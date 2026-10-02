with Ada.Calendar;
with Ada.Command_Line;
with Ada.Exceptions;
with Interfaces;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Strings.Wide_Wide_Unbounded;
with Ada.Text_IO;

with A11y.Actions;
with A11y.Capabilities;
with A11y.Dispatchers;
with A11y.Documents;
with A11y.Events;
with A11y.Geometry;
with A11y.Images;
with A11y.Live_Regions;
with A11y.Native_Callbacks;
with A11y.Native_Focus_Calls;
with A11y.Native_Identity;
with A11y.Native_Object_Caches;
with A11y.Native_Runtimes;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Properties;
with A11y.Relations;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Roles;
with A11y.Selection;
with A11y.States;
with A11y.Tables;
with A11y.Text;
with A11y.Trees;
with A11y.Values;
with A11y.Windows;
with A11y.Windows_Backend.UIA_ABI_Surface;
with A11y.Windows_Backend.UIA_Actions;
with A11y.Windows_Backend.UIA_COM_Exports;
with A11y.Windows_Backend.UIA_COM_Live_Exports;
with A11y.Windows_Backend.UIA_COM_Object_Exports;
with A11y.Windows_Backend.UIA_COM_VTables;
with A11y.Windows_Backend.UIA_Com_Providers;
with A11y.Windows_Backend.UIA_Document;
with A11y.Windows_Backend.UIA_Events;
with A11y.Windows_Backend.UIA_Fragments;
with A11y.Windows_Backend.UIA_Image;
with A11y.Windows_Backend.UIA_Live_Regions;
with A11y.Windows_Backend.UIA_Mappings;
with A11y.Windows_Backend.UIA_Properties;
with A11y.Windows_Backend.UIA_Native_Bridge;
with A11y.Windows_Backend.UIA_Native_Callbacks;
with A11y.Windows_Backend.UIA_Provider_Boundary;
with A11y.Windows_Backend.UIA_Provider_Registry;
with A11y.Windows_Backend.UIA_Public_Roots;
with A11y.Windows_Backend.UIA_Request_Router;
with A11y.Windows_Backend.UIA_Selection;
with A11y.Windows_Backend.UIA_Surfaces;
with A11y.Windows_Backend.UIA_Table;
with A11y.Windows_Backend.UIA_Text;
with A11y.Windows_Backend.UIA_Values;

with A11y_Native_Client_Reports;
with A11y_Test_Fixtures;
with A11y_UIA_Native_Probe_Callbacks;

procedure Native_Client_UIA is
   use Ada.Strings.Unbounded;
   use Ada.Strings.Wide_Wide_Unbounded;
   use type A11y.Results.Status_Code;
   use type A11y.Actions.Action_Id;
   use type A11y.Geometry.Coordinate;
   use type A11y.Geometry.Length;
   use type A11y.Geometry.Rectangle;
   use type A11y.Node_Ids.Node_Id;

   Fixture_Schema : constant String := "org.a11y.fixture_application.v1";
   use type A11y.Text.Text_Edit_Kind;
   use type A11y.Windows_Backend.UIA_Selection.Selection_Request_Kind;
   use type A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply_Kind;
   use type A11y.Windows_Backend.UIA_Provider_Boundary.HRESULT_Status;
   use type A11y.Windows_Backend.UIA_Provider_Boundary.UIA_Request_Kind;
   use type A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface;
   use type A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method;
   use type A11y.Native_Identity.Backend_Session_Id;
   use type A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id;
   use type A11y.Windows_Backend.UIA_Mappings.UIA_Relation_Property;
   use type A11y.Windows_Backend.UIA_Properties.Reply_Kind;
   use type A11y.Windows_Backend.UIA_Request_Router.Routed_Reply_Kind;
   use type Interfaces.Unsigned_32;

   function Trimmed (Text : String) return String is
     (Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both));

   function Q (Text : String) return String is
      Result : Unbounded_String := To_Unbounded_String ("""");
   begin
      for Ch of Text loop
         case Ch is
            when '"' =>
               Append (Result, "\""");
            when '\' =>
               Append (Result, "\\");
            when ASCII.LF =>
               Append (Result, "\n");
            when ASCII.CR =>
               Append (Result, "\r");
            when ASCII.HT =>
               Append (Result, "\t");
            when others =>
               if Character'Pos (Ch) < 32 then
                  Append (Result, " ");
               else
                  Append (Result, Ch);
               end if;
         end case;
      end loop;
      Append (Result, """");
      return To_String (Result);
   end Q;

   function Status_Name (Status : A11y.Results.Status_Code) return String is
     (Trimmed (A11y.Results.Status_Code'Image (Status)));

   type Probe_Focus_Node is new A11y.Nodes.Accessible_Node with record
      Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      State_Set : A11y.States.State_Set := A11y.States.Empty_State_Set;
   end record;

   overriding function Id
     (Self : Probe_Focus_Node)
      return A11y.Node_Ids.Node_Id is
     (Self.Node);

   overriding function Role
     (Self : Probe_Focus_Node)
      return A11y.Roles.Role is
     (A11y.Roles.Button);

   overriding function States
     (Self : Probe_Focus_Node)
      return A11y.States.State_Set is
     (Self.State_Set);

   overriding function Parent
     (Self : Probe_Focus_Node)
      return A11y.Node_Ids.Node_Id is
     (A11y.Node_Ids.No_Node);

   overriding function Child_Count
     (Self : Probe_Focus_Node)
      return Natural is
     (0);

   overriding function Child_At
     (Self  : Probe_Focus_Node;
      Index : Positive)
      return A11y.Node_Ids.Node_Id is
     (A11y.Node_Ids.No_Node);

   overriding function Name
     (Self : Probe_Focus_Node)
      return A11y.Properties.String_Property is
     (A11y.Properties.Present ("Focus probe"));

   overriding function Description
     (Self : Probe_Focus_Node)
      return A11y.Properties.String_Property is
     (A11y.Properties.Empty);

   overriding function Bounds
     (Self : Probe_Focus_Node)
      return A11y.Geometry.Rectangle is
     (A11y.Geometry.Empty_Rectangle);

   overriding function Capabilities
     (Self : Probe_Focus_Node)
      return A11y.Capabilities.Capability_Set is
     (A11y.Capabilities.With_Capability
        (A11y.Capabilities.Empty_Capability_Set,
         A11y.Capabilities.Action));

   overriding function Exposure
     (Self : Probe_Focus_Node)
      return A11y.Nodes.Exposure_Policy is
     (A11y.Nodes.Expose_Node);

   type Probe_Focus_Action_Provider is new A11y.Actions.Action_Provider
   with record
      Calls : Natural := 0;
   end record;

   overriding function Supports
     (Self   : Probe_Focus_Action_Provider;
      Action : A11y.Actions.Action_Id)
      return Boolean is
     (Action = A11y.Actions.Set_Focus);

   overriding function Invoke
     (Self   : in out Probe_Focus_Action_Provider;
      Node   : A11y.Node_Ids.Node_Id;
      Action : A11y.Actions.Action_Id)
      return A11y.Actions.Action_Result is
   begin
      if Action /= A11y.Actions.Set_Focus
        or else not A11y.Node_Ids.Is_Valid (Node)
      then
         return (Status => A11y.Results.Unsupported_Action);
      end if;

      Self.Calls := Self.Calls + 1;
      return (Status => A11y.Results.Success);
   end Invoke;

   procedure Emit_Fixture_Root_Probe is
      type Snapshot_Access is
        access all A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;

      Root : constant A11y.Node_Ids.Node_Id :=
        A11y_Test_Fixtures.Application_Id;
      Runtime : A11y.Native_Runtimes.Native_Runtime;
      Provider : A11y.Windows_Backend.UIA_Com_Providers.Provider_Object;
      Context :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Context;
      Call_Snapshot :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Snapshot;
      Snapshots :
        constant Snapshot_Access := new
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Boundary_Request :
        A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Request;
      Boundary_Reply :
        A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply;
      Result : A11y.Results.Result;
      Native_Component : Natural := 0;
      Root_Native_Component : Natural := 0;
      Started : Boolean := False;
      Provider_Created : Boolean := False;
      Native_Call_Admitted : Boolean := False;
      Native_Call_Completed : Boolean := False;
      Native_Call_Drained : Boolean := False;
      Root_Query_Dispatched : Boolean := False;
      Root_Child_Count_Dispatched : Boolean := False;
      Root_First_Child_Dispatched : Boolean := False;
      Root_Second_Child_Dispatched : Boolean := False;
      Fixture_Child_Query_Dispatched : Boolean := False;
      Fixture_Child_Role_Dispatched : Boolean := False;
      Fixture_Child_Parent_Dispatched : Boolean := False;
      Fixture_Child_Native_Identity_Dispatched : Boolean := False;
      Fixture_Second_Child_Parent_Dispatched : Boolean := False;
      Fixture_Second_Child_Native_Identity_Dispatched : Boolean := False;
      Fixture_Sibling_Order_Dispatched : Boolean := False;
      Boundary_Status : A11y.Results.Status_Code := A11y.Results.Internal_Error;
      End_Result : A11y.Results.Result;
      Provider_After_Call :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Snapshot;
      Registry :
        A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Registry_Id :
        A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id :=
          A11y.Windows_Backend.UIA_Provider_Registry.No_Provider;
      Child_Registry_Id :
        A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id :=
          A11y.Windows_Backend.UIA_Provider_Registry.No_Provider;
      Registry_View :
        A11y.Windows_Backend.UIA_Provider_Registry
          .Provider_Record_Snapshot;
      Registry_Report :
        A11y.Windows_Backend.UIA_Provider_Registry
          .Registry_Mutation_Report;
      Registry_Provider_Created : Boolean := False;
      Registry_Drained_Reset : Boolean := False;
      Registry_Node_Lookup_Rejected : Boolean := False;
      Registry_Stale_Id_Rejected : Boolean := False;
      Registry_Child_Provider_Created : Boolean := False;
      Registry_Child_Stale_Id_Rejected : Boolean := False;

      function Probe_Completed return Boolean is
        (Started
         and then Provider_Created
         and then Native_Call_Admitted
         and then Native_Call_Completed
         and then Native_Call_Drained
         and then Root_Query_Dispatched
         and then Root_Child_Count_Dispatched
         and then Root_First_Child_Dispatched
         and then Root_Second_Child_Dispatched
         and then Fixture_Child_Query_Dispatched
         and then Fixture_Child_Role_Dispatched
         and then Fixture_Child_Parent_Dispatched
         and then Fixture_Child_Native_Identity_Dispatched
         and then Fixture_Second_Child_Parent_Dispatched
         and then Fixture_Second_Child_Native_Identity_Dispatched
         and then Fixture_Sibling_Order_Dispatched
         and then Registry_Provider_Created
         and then Registry_Child_Provider_Created
         and then Registry_Drained_Reset
         and then Registry_Node_Lookup_Rejected
         and then Registry_Stale_Id_Rejected
         and then Registry_Child_Stale_Id_Rejected
         and then Boundary_Status = A11y.Results.Success);

      function Failure_Stage return String is
      begin
         if not Started then
            return "runtime_start";
         elsif not Provider_Created then
            return "provider_creation";
         elsif not Native_Call_Admitted then
            return "native_call_admission";
         elsif not Root_Query_Dispatched then
            return "fixture_root_query";
         elsif not Root_Child_Count_Dispatched then
            return "fixture_root_child_count";
         elsif not Root_First_Child_Dispatched then
            return "fixture_root_first_child";
         elsif not Root_Second_Child_Dispatched then
            return "fixture_root_second_child";
         elsif not Fixture_Child_Query_Dispatched then
            return "fixture_child_query";
         elsif not Fixture_Child_Role_Dispatched then
            return "fixture_child_role";
         elsif not Fixture_Child_Parent_Dispatched then
            return "fixture_child_parent";
         elsif not Fixture_Child_Native_Identity_Dispatched then
            return "fixture_child_native_identity";
         elsif not Fixture_Second_Child_Parent_Dispatched then
            return "fixture_second_child_parent";
         elsif not Fixture_Second_Child_Native_Identity_Dispatched then
            return "fixture_second_child_native_identity";
         elsif not Fixture_Sibling_Order_Dispatched then
            return "fixture_sibling_order";
         elsif not Native_Call_Completed then
            return "native_call_completion";
         elsif not Native_Call_Drained then
            return "native_call_drain";
         elsif not Registry_Provider_Created then
            return "registry_provider_creation";
         elsif not Registry_Child_Provider_Created then
            return "registry_child_provider_creation";
         elsif not Registry_Drained_Reset then
            return "registry_reset";
         elsif not Registry_Node_Lookup_Rejected then
            return "reset_node_rejection";
         elsif not Registry_Stale_Id_Rejected then
            return "reset_stale_id_rejection";
         elsif not Registry_Child_Stale_Id_Rejected then
            return "reset_child_stale_id_rejection";
         elsif Boundary_Status /= A11y.Results.Success then
            return "boundary_status";
         else
            return "none";
         end if;
      end Failure_Stage;
   begin
      A11y.Native_Runtimes.Start (Runtime, Result);
      Started := A11y.Results.Succeeded (Result);

      if Started then
         A11y.Windows_Backend.UIA_Com_Providers.Initialize
           (Provider,
            A11y.Native_Runtimes.Session (Runtime),
            Root,
            Root,
            Result);
         Provider_Created := A11y.Results.Succeeded (Result);
      end if;

      if Provider_Created then
         A11y.Windows_Backend.UIA_Com_Providers.Begin_Native_Call
           (Provider,
            A11y.Windows_Backend.UIA_Com_Providers.Raw_Element_Provider_Simple,
            Context,
            Result);
         Call_Snapshot :=
           A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Context);
         Native_Call_Admitted :=
           A11y.Results.Succeeded (Result) and then Call_Snapshot.Active;
      end if;

      if Native_Call_Admitted then
         Native_Component :=
           A11y.Native_Identity.Runtime_Identifier_Component
             (A11y.Native_Runtimes.Session (Runtime), Root, Result);
         Root_Native_Component := Native_Component;

         Snapshots.all.Properties.Id := Root;
         Snapshots.all.Properties.Root := Root;
         Snapshots.all.Fragment.Session :=
           A11y.Native_Runtimes.Session (Runtime);
         A11y.Trees.Set_Root (Snapshots.all.Properties.Tree, Root, Result);
         A11y.Trees.Set_Root (Snapshots.all.Fragment.Tree, Root, Result);
         A11y.Trees.Attach
           (Snapshots.all.Fragment.Tree,
            Root,
            A11y_Test_Fixtures.Main_Window_Id,
            Result);
         A11y.Trees.Attach
           (Snapshots.all.Fragment.Tree,
            Root,
            A11y_Test_Fixtures.Dialog_Id,
            Result);
         Snapshots.all.Fragment.Fragment_Root := Root;
         Snapshots.all.Fragment.Node := Root;
         Snapshots.all.Properties.Role := A11y.Roles.Application;
         Snapshots.all.Properties.Name :=
           A11y.Properties.Present ("Fixture Application");

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Property_Value;
         Boundary_Request.Property := A11y.Windows_Backend.UIA_Properties.Name;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Boundary_Status := Boundary_Reply.Status;
         Root_Query_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Status = A11y.Results.Success;

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Navigate_Fragment;
         Boundary_Request.Direction :=
           A11y.Windows_Backend.UIA_Fragments.First_Child;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Root_First_Child_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Fragment_Node
           and then Boundary_Reply.Payload.Node =
             A11y_Test_Fixtures.Main_Window_Id;

         Boundary_Request.Direction :=
           A11y.Windows_Backend.UIA_Fragments.Last_Child;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Root_Second_Child_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Fragment_Node
           and then Boundary_Reply.Payload.Node =
             A11y_Test_Fixtures.Dialog_Id;

         Snapshots.all.Properties.Id := A11y_Test_Fixtures.Main_Window_Id;
         Snapshots.all.Properties.Root := Root;
         Snapshots.all.Properties.Role := A11y.Roles.Window;
         Snapshots.all.Properties.Name :=
           A11y.Properties.Present ("Main Window");
         Native_Component :=
           A11y.Native_Identity.Runtime_Identifier_Component
             (A11y.Native_Runtimes.Session (Runtime),
              A11y_Test_Fixtures.Main_Window_Id,
              Result);
         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Property_Value;
         Boundary_Request.Property := A11y.Windows_Backend.UIA_Properties.Name;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Fixture_Child_Query_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Property_String;

         Boundary_Request.Property :=
           A11y.Windows_Backend.UIA_Properties.Control_Type;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Fixture_Child_Role_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Property_Control_Type;

         Snapshots.all.Fragment.Node := A11y_Test_Fixtures.Main_Window_Id;
         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Navigate_Fragment;
         Boundary_Request.Direction :=
           A11y.Windows_Backend.UIA_Fragments.Parent;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Fixture_Child_Parent_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Fragment_Node
           and then Boundary_Reply.Payload.Node = Root;

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Runtime_Id;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Fixture_Child_Native_Identity_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Runtime_Id
           and then Boundary_Reply.Payload.Id.Root_Component =
             Root_Native_Component
           and then Boundary_Reply.Payload.Id.Node_Component =
             Native_Component;

         Snapshots.all.Fragment.Node := A11y_Test_Fixtures.Dialog_Id;
         Boundary_Request.Native_Node_Component :=
           A11y.Native_Identity.Runtime_Identifier_Component
             (A11y.Native_Runtimes.Session (Runtime),
              A11y_Test_Fixtures.Dialog_Id,
              Result);
         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Navigate_Fragment;
         Boundary_Request.Direction :=
           A11y.Windows_Backend.UIA_Fragments.Parent;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Fixture_Second_Child_Parent_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Fragment_Node
           and then Boundary_Reply.Payload.Node = Root;

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Runtime_Id;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Fixture_Second_Child_Native_Identity_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Runtime_Id
           and then Boundary_Reply.Payload.Id.Root_Component =
             Root_Native_Component
           and then Boundary_Reply.Payload.Id.Node_Component =
             Boundary_Request.Native_Node_Component;

         declare
            Next_Matches : Boolean := False;
            Previous_Matches : Boolean := False;
            No_Third_Matches : Boolean := False;
         begin
            Snapshots.all.Fragment.Node := A11y_Test_Fixtures.Main_Window_Id;
            Boundary_Request.Native_Node_Component :=
              A11y.Native_Identity.Runtime_Identifier_Component
                (A11y.Native_Runtimes.Session (Runtime),
                 A11y_Test_Fixtures.Main_Window_Id,
                 Result);
            Boundary_Request.Kind :=
              A11y.Windows_Backend.UIA_Provider_Boundary.Navigate_Fragment;
            Boundary_Request.Direction :=
              A11y.Windows_Backend.UIA_Fragments.Next_Sibling;
            Boundary_Reply :=
              A11y.Windows_Backend.UIA_Provider_Boundary
                .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
            Next_Matches :=
              Boundary_Reply.Kind =
                A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
              and then Boundary_Reply.HResult =
                A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
              and then Boundary_Reply.Status = A11y.Results.Success
              and then Boundary_Reply.Routed =
                A11y.Windows_Backend.UIA_Request_Router.Fragment_Node
              and then Boundary_Reply.Payload.Node =
                A11y_Test_Fixtures.Dialog_Id;

            Snapshots.all.Fragment.Node := A11y_Test_Fixtures.Dialog_Id;
            Boundary_Request.Native_Node_Component :=
              A11y.Native_Identity.Runtime_Identifier_Component
                (A11y.Native_Runtimes.Session (Runtime),
                 A11y_Test_Fixtures.Dialog_Id,
                 Result);
            Boundary_Request.Direction :=
              A11y.Windows_Backend.UIA_Fragments.Previous_Sibling;
            Boundary_Reply :=
              A11y.Windows_Backend.UIA_Provider_Boundary
                .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
            Previous_Matches :=
              Boundary_Reply.Kind =
                A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
              and then Boundary_Reply.HResult =
                A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
              and then Boundary_Reply.Status = A11y.Results.Success
              and then Boundary_Reply.Routed =
                A11y.Windows_Backend.UIA_Request_Router.Fragment_Node
              and then Boundary_Reply.Payload.Node =
                A11y_Test_Fixtures.Main_Window_Id;

            Boundary_Request.Direction :=
              A11y.Windows_Backend.UIA_Fragments.Next_Sibling;
            Boundary_Reply :=
              A11y.Windows_Backend.UIA_Provider_Boundary
                .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
            No_Third_Matches :=
              Boundary_Reply.Kind =
                A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
              and then Boundary_Reply.HResult =
                A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
              and then Boundary_Reply.Status = A11y.Results.Success
              and then Boundary_Reply.Routed =
                A11y.Windows_Backend.UIA_Request_Router.Fragment_Empty;

            Root_Child_Count_Dispatched :=
              Root_First_Child_Dispatched
              and then Root_Second_Child_Dispatched
              and then No_Third_Matches;
            Fixture_Sibling_Order_Dispatched :=
              Next_Matches and then Previous_Matches;
         end;

         A11y.Windows_Backend.UIA_Com_Providers.End_Native_Call
           (Provider,
            Context,
            End_Result);
         Provider_After_Call :=
           A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Provider);
         Native_Call_Completed :=
           A11y.Results.Succeeded (End_Result)
           and then not
             A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Context).Active
           and then Provider_After_Call.Active_Calls = 0
           and then Provider_After_Call.Call_Generation >
             Call_Snapshot.Native_Call_Generation;
         Native_Call_Drained :=
           Native_Call_Completed
           and then A11y.Windows_Backend.UIA_Com_Providers.Drained
             (Provider);
      end if;

      if Started then
         A11y.Windows_Backend.UIA_Provider_Registry.Ensure_Provider
           (Registry,
            A11y.Native_Runtimes.Session (Runtime),
            Root,
            Root,
            Registry_Id,
            Result);
         Registry_Provider_Created := A11y.Results.Succeeded (Result);
      end if;

      if Registry_Provider_Created then
         A11y.Windows_Backend.UIA_Provider_Registry.Ensure_Provider
           (Registry,
            A11y.Native_Runtimes.Session (Runtime),
            Root,
            A11y_Test_Fixtures.Main_Window_Id,
            Child_Registry_Id,
            Result);
         Registry_Child_Provider_Created := A11y.Results.Succeeded (Result);
      end if;

      if Registry_Child_Provider_Created then
         A11y.Windows_Backend.UIA_Provider_Registry.Release
           (Registry,
            A11y.Native_Runtimes.Session (Runtime),
            Child_Registry_Id,
            Result);
         if A11y.Results.Succeeded (Result) then
            A11y.Windows_Backend.UIA_Provider_Registry.Release
              (Registry,
               A11y.Native_Runtimes.Session (Runtime),
               Registry_Id,
               Result);
         end if;
      end if;

      if Registry_Child_Provider_Created and then A11y.Results.Succeeded (Result)
      then
         A11y.Windows_Backend.UIA_Provider_Registry
           .Reset_When_Drained_With_Report
             (Registry, Registry_Report, Result);
         Registry_Drained_Reset :=
           A11y.Results.Succeeded (Result)
           and then Registry_Report.Generation_Advanced
           and then Registry_Report.Live_After = 0
           and then Registry_Report.Tombstones_After = 0
           and then Registry_Report.Outstanding_After = 0;
      end if;

      if Registry_Drained_Reset then
         A11y.Windows_Backend.UIA_Provider_Registry.Find_Provider
           (Registry,
            A11y.Native_Runtimes.Session (Runtime),
            Root,
            Registry_View,
            Result);
         Registry_Node_Lookup_Rejected :=
           Result.Status = A11y.Results.Node_Unavailable
           and then Registry_View.Id =
             A11y.Windows_Backend.UIA_Provider_Registry.No_Provider;

         A11y.Windows_Backend.UIA_Provider_Registry.Resolve_Provider
           (Registry,
            A11y.Native_Runtimes.Session (Runtime),
            Registry_Id,
            Registry_View,
            Result);
         Registry_Stale_Id_Rejected :=
           Result.Status = A11y.Results.Node_Unavailable
           and then Registry_View.Id =
             A11y.Windows_Backend.UIA_Provider_Registry.No_Provider;

         A11y.Windows_Backend.UIA_Provider_Registry.Resolve_Provider
           (Registry,
            A11y.Native_Runtimes.Session (Runtime),
            Child_Registry_Id,
            Registry_View,
            Result);
         Registry_Child_Stale_Id_Rejected :=
           Result.Status = A11y.Results.Node_Unavailable
           and then Registry_View.Id =
             A11y.Windows_Backend.UIA_Provider_Registry.No_Provider;
      end if;

      Ada.Text_IO.Put_Line ("{");
      Ada.Text_IO.Put_Line
        ("  ""schema"": "
         & Q ("org.a11y.native_client_uia_fixture_root.v1")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_schema"": " & Q (Fixture_Schema) & ",");
      Ada.Text_IO.Put_Line
        ("  ""client_process"": "
         & Q (A11y_Native_Client_Reports.Client_Process_Name
                (A11y_Native_Client_Reports.Windows_UIA))
         & ",");
      Ada.Text_IO.Put_Line ("  ""platform"": ""Windows"",");
      Ada.Text_IO.Put_Line ("  ""native_api"": ""UI Automation"",");
      Ada.Text_IO.Put_Line
        ("  ""application_node"": " & Q (A11y.Node_Ids.Image (Root)) & ",");
      Ada.Text_IO.Put_Line
        ("  ""runtime_started"": "
         & (if Started then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_provider_created"": "
         & (if Provider_Created then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_call_admitted"": "
         & (if Native_Call_Admitted then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_call_completed"": "
         & (if Native_Call_Completed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_call_drained"": "
         & (if Native_Call_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_call_token"": "
         & Natural'Image (Call_Snapshot.Native_Call_Token)
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_call_start_generation"": "
         & Natural'Image (Call_Snapshot.Native_Call_Generation)
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_call_final_generation"": "
         & Natural'Image (Provider_After_Call.Call_Generation)
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_call_active_after_completion"": "
         & Natural'Image (Provider_After_Call.Active_Calls)
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_root_query_dispatched"": "
         & (if Root_Query_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_root_child_count_dispatched"": "
         & (if Root_Child_Count_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_root_first_child_dispatched"": "
         & (if Root_First_Child_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_root_second_child_dispatched"": "
         & (if Root_Second_Child_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_child_query_dispatched"": "
         & (if Fixture_Child_Query_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_child_role_dispatched"": "
         & (if Fixture_Child_Role_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_child_parent_dispatched"": "
         & (if Fixture_Child_Parent_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_child_native_identity_dispatched"": "
         & (if Fixture_Child_Native_Identity_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_second_child_parent_dispatched"": "
         & (if Fixture_Second_Child_Parent_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_second_child_native_identity_dispatched"": "
         & (if Fixture_Second_Child_Native_Identity_Dispatched
            then "true"
            else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_sibling_order_dispatched"": "
         & (if Fixture_Sibling_Order_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registry_provider_created"": "
         & (if Registry_Provider_Created then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registry_child_provider_created"": "
         & (if Registry_Child_Provider_Created then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registry_drained_reset"": "
         & (if Registry_Drained_Reset then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registry_node_lookup_rejected_after_reset"": "
         & (if Registry_Node_Lookup_Rejected then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registry_stale_id_rejected_after_reset"": "
         & (if Registry_Stale_Id_Rejected then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registry_child_stale_id_rejected_after_reset"": "
         & (if Registry_Child_Stale_Id_Rejected then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""probe_status"": "
         & Q (if Probe_Completed then "success" else "incomplete")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""failure_stage"": " & Q (Failure_Stage) & ",");
      Ada.Text_IO.Put_Line
        ("  ""boundary_status"": " & Q (Status_Name (Boundary_Status)));
      Ada.Text_IO.Put_Line ("}");
   exception
      when others =>
         Ada.Text_IO.Put_Line ("{");
         Ada.Text_IO.Put_Line
           ("  ""schema"": "
            & Q ("org.a11y.native_client_uia_fixture_root.v1")
            & ",");
         Ada.Text_IO.Put_Line
           ("  ""fixture_schema"": " & Q (Fixture_Schema) & ",");
         Ada.Text_IO.Put_Line ("  ""client_process"": ""native_client_uia"",");
         Ada.Text_IO.Put_Line ("  ""platform"": ""Windows"",");
         Ada.Text_IO.Put_Line ("  ""native_api"": ""UI Automation"",");
         Ada.Text_IO.Put_Line ("  ""application_node"": ""1001"",");
         Ada.Text_IO.Put_Line ("  ""runtime_started"": false,");
         Ada.Text_IO.Put_Line ("  ""native_provider_created"": false,");
         Ada.Text_IO.Put_Line ("  ""native_call_admitted"": false,");
         Ada.Text_IO.Put_Line ("  ""native_call_completed"": false,");
         Ada.Text_IO.Put_Line ("  ""native_call_drained"": false,");
         Ada.Text_IO.Put_Line ("  ""native_call_token"": 0,");
         Ada.Text_IO.Put_Line ("  ""native_call_start_generation"": 0,");
         Ada.Text_IO.Put_Line ("  ""native_call_final_generation"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""native_call_active_after_completion"": 0,");
         Ada.Text_IO.Put_Line ("  ""fixture_root_query_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fixture_root_child_count_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fixture_root_first_child_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fixture_root_second_child_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fixture_child_query_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fixture_child_role_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fixture_child_parent_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fixture_child_native_identity_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fixture_second_child_parent_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fixture_second_child_native_identity_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fixture_sibling_order_dispatched"": false,");
         Ada.Text_IO.Put_Line ("  ""registry_provider_created"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registry_child_provider_created"": false,");
         Ada.Text_IO.Put_Line ("  ""registry_drained_reset"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registry_node_lookup_rejected_after_reset"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registry_stale_id_rejected_after_reset"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registry_child_stale_id_rejected_after_reset"": false,");
         Ada.Text_IO.Put_Line ("  ""probe_status"": ""failed"",");
         Ada.Text_IO.Put_Line ("  ""failure_stage"": ""exception"",");
         Ada.Text_IO.Put_Line ("  ""boundary_status"": ""INTERNAL_ERROR""");
         Ada.Text_IO.Put_Line ("}");
   end Emit_Fixture_Root_Probe;

   procedure Emit_Registered_Boundary_Probe is
      type Snapshot_Access is
        access all A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;

      Root : constant A11y.Node_Ids.Node_Id :=
        A11y_Test_Fixtures.Application_Id;
      Runtime : A11y.Native_Runtimes.Native_Runtime;
      Registry :
        A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Provider :
        A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id :=
          A11y.Windows_Backend.UIA_Provider_Registry.No_Provider;
      Snapshots :
        constant Snapshot_Access := new
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Boundary_Request :
        A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Request;
      Boundary_Reply :
        A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply;
      Boundary_Report :
        A11y.Windows_Backend.UIA_Provider_Boundary
          .Registered_Native_Request_Report;
      Result : A11y.Results.Result;
      Started : Boolean := False;
      Provider_Created : Boolean := False;
      Boundary_Dispatched : Boolean := False;
      Boundary_Report_Complete : Boolean := False;

      function Probe_Completed return Boolean is
        (Started
         and then Provider_Created
         and then Boundary_Dispatched
         and then Boundary_Report_Complete);

      function Failure_Stage return String is
      begin
         if not Started then
            return "runtime_start";
         elsif not Provider_Created then
            return "provider_creation";
         elsif not Boundary_Dispatched then
            return "registered_boundary_dispatch";
         elsif not Boundary_Report_Complete then
            return "registered_boundary_report";
         else
            return "none";
         end if;
      end Failure_Stage;
   begin
      A11y.Native_Runtimes.Start (Runtime, Result);
      Started := A11y.Results.Succeeded (Result);

      if Started then
         A11y.Windows_Backend.UIA_Provider_Registry.Ensure_Provider
           (Registry,
            A11y.Native_Runtimes.Session (Runtime),
            Root,
            Root,
            Provider,
            Result);
         Provider_Created := A11y.Results.Succeeded (Result);
      end if;

      if Provider_Created then
         Snapshots.all.Properties.Id := Root;
         Snapshots.all.Properties.Root := Root;
         Snapshots.all.Fragment.Session :=
           A11y.Native_Runtimes.Session (Runtime);
         Snapshots.all.Properties.Role := A11y.Roles.Button;
         Snapshots.all.Properties.Name := A11y.Properties.Present ("Press");
         Snapshots.all.Actions (A11y.Actions.Press) := True;
         Snapshots.all.Action_Node := Root;
         Snapshots.all.Action_Root := Root;
         A11y.Trees.Set_Root (Snapshots.all.Action_Tree, Root, Result);

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Invoke_Action;
         Boundary_Request.Action := A11y.Actions.Press;
         Boundary_Request.Has_Native_Identity := False;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary
             .Dispatch_Registered_Native_Request_With_Report
               (Registry,
                A11y.Native_Runtimes.Session (Runtime),
                Provider,
                A11y.Windows_Backend.UIA_Com_Providers
                  .Raw_Element_Provider_Simple,
                Boundary_Request,
                Snapshots.all,
                Boundary_Report);

         Boundary_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success;
         Boundary_Report_Complete :=
           Boundary_Report.Interface_Supported
           and then Boundary_Report.Requested_Interface =
             A11y.Windows_Backend.UIA_Com_Providers
               .Raw_Element_Provider_Simple
           and then Boundary_Report.Request_Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Invoke_Action
           and then Boundary_Report.Resolved
           and then Boundary_Report.Resolved_Node = Root
           and then Boundary_Report.Resolved_Root = Root
           and then Boundary_Report.Native_Node_Component /= 0
           and then Boundary_Report.Native_Identity_Prepared
           and then Boundary_Report.Native_Admitted
           and then Boundary_Report.Native_Completed
           and then Boundary_Report.Begin_Report.Outstanding_Before = 0
           and then Boundary_Report.Begin_Report.Outstanding_After = 1
           and then Boundary_Report.End_Report.Outstanding_Before = 1
           and then Boundary_Report.End_Report.Outstanding_After = 0
           and then not Boundary_Report.End_Report.Call_Active
           and then Boundary_Report.Reply_Status = A11y.Results.Success
           and then Boundary_Report.Final_Status = A11y.Results.Success;
      end if;

      Ada.Text_IO.Put_Line ("{");
      Ada.Text_IO.Put_Line
        ("  ""schema"": "
         & Q ("org.a11y.native_client_uia_registered_boundary_probe.v1")
         & ",");
      Ada.Text_IO.Put_Line ("  ""client_process"": ""native_client_uia"",");
      Ada.Text_IO.Put_Line ("  ""platform"": ""Windows"",");
      Ada.Text_IO.Put_Line ("  ""native_api"": ""UI Automation"",");
      Ada.Text_IO.Put_Line
        ("  ""runtime_started"": "
         & (if Started then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registry_provider_created"": "
         & (if Provider_Created then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_dispatched"": "
         & (if Boundary_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_report_complete"": "
         & (if Boundary_Report_Complete then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_interface_supported"": "
         & (if Boundary_Report.Interface_Supported then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_requested_interface"": "
         & Q
           (A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface'Image
              (Boundary_Report.Requested_Interface))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_request_kind"": "
         & Q
           (A11y.Windows_Backend.UIA_Provider_Boundary.UIA_Request_Kind'Image
              (Boundary_Report.Request_Kind))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_resolved"": "
         & (if Boundary_Report.Resolved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_resolved_node"": "
         & Q (A11y.Node_Ids.Image (Boundary_Report.Resolved_Node))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_resolved_root"": "
         & Q (A11y.Node_Ids.Image (Boundary_Report.Resolved_Root))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_native_node_component"": "
         & Trimmed (Natural'Image (Boundary_Report.Native_Node_Component))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_native_identity_prepared"": "
         & (if Boundary_Report.Native_Identity_Prepared
            then "true"
            else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_admitted"": "
         & (if Boundary_Report.Native_Admitted then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_completed"": "
         & (if Boundary_Report.Native_Completed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_begin_outstanding_before"": "
         & Trimmed
             (Natural'Image
                (Boundary_Report.Begin_Report.Outstanding_Before))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_begin_outstanding_after"": "
         & Trimmed
             (Natural'Image
                (Boundary_Report.Begin_Report.Outstanding_After))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_end_outstanding_before"": "
         & Trimmed
             (Natural'Image
                (Boundary_Report.End_Report.Outstanding_Before))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_end_outstanding_after"": "
         & Trimmed
             (Natural'Image
                (Boundary_Report.End_Report.Outstanding_After))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_reply_status"": "
         & Q (Status_Name (Boundary_Report.Reply_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_final_status"": "
         & Q (Status_Name (Boundary_Report.Final_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""probe_status"": "
         & Q (if Probe_Completed then "success" else "incomplete")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""failure_stage"": " & Q (Failure_Stage));
      Ada.Text_IO.Put_Line ("}");
   exception
      when others =>
         Ada.Text_IO.Put_Line ("{");
         Ada.Text_IO.Put_Line
           ("  ""schema"": "
            & Q ("org.a11y.native_client_uia_registered_boundary_probe.v1")
            & ",");
         Ada.Text_IO.Put_Line ("  ""client_process"": ""native_client_uia"",");
         Ada.Text_IO.Put_Line ("  ""platform"": ""Windows"",");
         Ada.Text_IO.Put_Line ("  ""native_api"": ""UI Automation"",");
         Ada.Text_IO.Put_Line ("  ""runtime_started"": false,");
         Ada.Text_IO.Put_Line ("  ""registry_provider_created"": false,");
         Ada.Text_IO.Put_Line ("  ""registered_boundary_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_report_complete"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_interface_supported"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_requested_interface"": ""UNSUPPORTED_INTERFACE"",");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_request_kind"": ""GET_PROPERTY_VALUE"",");
         Ada.Text_IO.Put_Line ("  ""registered_boundary_resolved"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_resolved_node"": ""none"",");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_resolved_root"": ""none"",");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_native_node_component"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_native_identity_prepared"": false,");
         Ada.Text_IO.Put_Line ("  ""registered_boundary_admitted"": false,");
         Ada.Text_IO.Put_Line ("  ""registered_boundary_completed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_begin_outstanding_before"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_begin_outstanding_after"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_end_outstanding_before"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_end_outstanding_after"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_reply_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_final_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line ("  ""probe_status"": ""failed"",");
         Ada.Text_IO.Put_Line ("  ""failure_stage"": ""exception""");
         Ada.Text_IO.Put_Line ("}");
   end Emit_Registered_Boundary_Probe;

   procedure Emit_Runtime_Probe is
      type Snapshot_Access is
        access all A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;

      Root : constant A11y.Node_Ids.Node_Id := A11y.Node_Ids.From_Natural (1);
      Fragment_Child : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (773);
      Table_Cell : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (771);
      Selection_Item : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (772);
      Runtime : A11y.Native_Runtimes.Native_Runtime;
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Emission : A11y.Windows_Backend.UIA_Events.UIA_Event_Emission;
      Report : A11y.Windows_Backend.UIA_Events.Event_Build_Report;
      Result : A11y.Results.Result;
      Event : constant A11y.Events.Event :=
        (Sequence  => 1,
         Timestamp => Ada.Calendar.Clock,
         Source    => Root,
         Kind      => A11y.Events.Focus_Changed,
         Revision  => 1);
      Provider : A11y.Windows_Backend.UIA_Com_Providers.Provider_Object;
      Context :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Context;
      Call_Snapshot :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Snapshot;
      Native_Component : Natural := 0;
      Selection_Component : Natural := 0;
      Snapshots :
        constant Snapshot_Access := new
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Boundary_Request :
        A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Request;
      Boundary_Reply :
        A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply;
      Started : Boolean := False;
      Prepared_OK : Boolean := False;
      Native_Provider_Created : Boolean := False;
      Native_Call_Admitted : Boolean := False;
      Native_Call_Completed : Boolean := False;
      Native_Call_Drained : Boolean := False;
      Host_Window_Bound : Boolean := False;
      Host_Window_Component : Natural := 0;
      Boundary_Query_Dispatched : Boolean := False;
      Automation_Id_Dispatched : Boolean := False;
      Automation_Id_Payload_Preserved : Boolean := False;
      Action_Discovery_Dispatched : Boolean := False;
      Action_Payload_Preserved : Boolean := False;
      Action_Request_Dispatched : Boolean := False;
      Action_Request_Payload_Preserved : Boolean := False;
      Text_Range_Dispatched : Boolean := False;
      Text_Range_Payload_Preserved : Boolean := False;
      Text_Edit_Dispatched : Boolean := False;
      Text_Edit_Payload_Preserved : Boolean := False;
      Text_Delete_Dispatched : Boolean := False;
      Text_Delete_Payload_Preserved : Boolean := False;
      Text_Replace_Dispatched : Boolean := False;
      Text_Replace_Payload_Preserved : Boolean := False;
      Text_Set_Dispatched : Boolean := False;
      Text_Set_Payload_Preserved : Boolean := False;
      Table_Current_Cell_Dispatched : Boolean := False;
      Table_Current_Cell_Payload_Preserved : Boolean := False;
      Table_Sort_Order_Dispatched : Boolean := False;
      Table_Sort_Order_Payload_Preserved : Boolean := False;
      Table_Sort_Key_Dispatched : Boolean := False;
      Table_Sort_Key_Payload_Preserved : Boolean := False;
      Value_Current_Dispatched : Boolean := False;
      Value_Current_Payload_Preserved : Boolean := False;
      Value_Set_Dispatched : Boolean := False;
      Value_Set_Payload_Preserved : Boolean := False;
      Selection_Count_Dispatched : Boolean := False;
      Selection_Count_Payload_Preserved : Boolean := False;
      Selection_Item_Dispatched : Boolean := False;
      Selection_Item_Payload_Preserved : Boolean := False;
      Selection_Request_Dispatched : Boolean := False;
      Selection_Request_Payload_Preserved : Boolean := False;
      Selection_Select_All_Dispatched : Boolean := False;
      Selection_Select_All_Payload_Preserved : Boolean := False;
      Selection_Clear_Dispatched : Boolean := False;
      Selection_Clear_Payload_Preserved : Boolean := False;
      Relation_Target_Dispatched : Boolean := False;
      Relation_Target_Payload_Preserved : Boolean := False;
      Document_Title_Dispatched : Boolean := False;
      Document_Title_Payload_Preserved : Boolean := False;
      Document_Heading_Dispatched : Boolean := False;
      Document_Heading_Payload_Preserved : Boolean := False;
      Image_Description_Dispatched : Boolean := False;
      Image_Description_Payload_Preserved : Boolean := False;
      Image_Size_Dispatched : Boolean := False;
      Image_Size_Payload_Preserved : Boolean := False;
      Live_Setting_Dispatched : Boolean := False;
      Live_Setting_Payload_Preserved : Boolean := False;
      Live_Atomic_Dispatched : Boolean := False;
      Live_Atomic_Payload_Preserved : Boolean := False;
      Surface_Kind_Dispatched : Boolean := False;
      Surface_Kind_Payload_Preserved : Boolean := False;
      Surface_Active_Dispatched : Boolean := False;
      Surface_Active_Payload_Preserved : Boolean := False;
      Missing_Identity_Rejected : Boolean := False;
      Mismatched_Identity_Rejected : Boolean := False;
      Malformed_Identity_Rejected : Boolean := False;
      Text_Payload_Limit_Rejected : Boolean := False;
      Boundary_Status : A11y.Results.Status_Code := A11y.Results.Internal_Error;
      End_Result : A11y.Results.Result;
      Provider_After_Call :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Snapshot;
      Provider_Export :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Export_Descriptor;
      Provider_Registry :
        A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Provider_Id :
        A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id :=
          A11y.Windows_Backend.UIA_Provider_Registry.No_Provider;
      Export_Table :
        A11y.Windows_Backend.UIA_COM_Exports.COM_Export_Table;
      Object_Descriptor :
        A11y.Windows_Backend.UIA_COM_VTables.COM_Object_Descriptor;
      Query_Plan :
        A11y.Windows_Backend.UIA_COM_VTables.Interface_Query_Plan;
      Frame_Plan :
        A11y.Windows_Backend.UIA_COM_VTables.Callback_Frame_Plan;
      Object_Export_Table :
        A11y.Windows_Backend.UIA_COM_Object_Exports.COM_Object_Export_Table;
      Object_Export :
        A11y.Windows_Backend.UIA_COM_Object_Exports.Object_Export_Report;
      Object_Resolve :
        A11y.Windows_Backend.UIA_COM_Object_Exports.Object_Resolve_Report;
      Object_Release :
        A11y.Windows_Backend.UIA_COM_Object_Exports.Object_Release_Report;
      Second_Object_Export :
        A11y.Windows_Backend.UIA_COM_Object_Exports.Object_Export_Report;
      Live_Interface_Query :
        A11y.Windows_Backend.UIA_COM_Live_Exports.Interface_Query_Report;
      Live_Fragment_Interface_Query :
        A11y.Windows_Backend.UIA_COM_Live_Exports.Interface_Query_Report;
      Live_Interface :
        A11y.Windows_Backend.UIA_COM_Live_Exports.UIA_Interface_Reference;
      Released_Live_Interface :
        A11y.Windows_Backend.UIA_COM_Live_Exports.UIA_Interface_Reference;
      Live_Fragment_Interface :
        A11y.Windows_Backend.UIA_COM_Live_Exports.UIA_Interface_Reference;
      Live_Interface_Add_Ref :
        A11y.Windows_Backend.UIA_COM_Live_Exports.Interface_Lifetime_Report;
      Live_Interface_Release :
        A11y.Windows_Backend.UIA_COM_Live_Exports.Interface_Lifetime_Report;
      Live_Interface_Final_Release :
        A11y.Windows_Backend.UIA_COM_Live_Exports.Interface_Lifetime_Report;
      Live_Interface_Dispatch :
        A11y.Windows_Backend.UIA_COM_Live_Exports.Interface_Dispatch_Report;
      Released_Live_Interface_Dispatch :
        A11y.Windows_Backend.UIA_COM_Live_Exports.Interface_Dispatch_Report;
      Rejected_Live_Interface_Dispatch :
        A11y.Windows_Backend.UIA_COM_Live_Exports.Interface_Dispatch_Report;
      Live_Interface_Frame :
        A11y.Windows_Backend.UIA_COM_Live_Exports.ABI_Interface_Frame;
      Rejected_Live_Interface_Frame :
        A11y.Windows_Backend.UIA_COM_Live_Exports.ABI_Interface_Frame;
      Live_Interface_Frame_Dispatch :
        A11y.Windows_Backend.UIA_COM_Live_Exports
          .ABI_Interface_Frame_Report;
      Rejected_Live_Interface_Frame_Dispatch :
        A11y.Windows_Backend.UIA_COM_Live_Exports
          .ABI_Interface_Frame_Report;
      COM_VTable_Descriptor_Built : Boolean := False;
      COM_VTable_QueryInterface_Planned : Boolean := False;
      COM_VTable_Frame_Planned : Boolean := False;
      COM_Object_Token_Exported : Boolean := False;
      COM_Object_Token_Resolved : Boolean := False;
      COM_Object_Token_Released : Boolean := False;
      COM_Object_Token_Not_Reused : Boolean := False;
      COM_Live_Interface_Queried : Boolean := False;
      COM_Live_Interface_Retained : Boolean := False;
      COM_Live_Interface_Released : Boolean := False;
      COM_Live_Released_Interface_Rejected : Boolean := False;
      COM_Live_Interface_Dispatched : Boolean := False;
      COM_Live_Interface_Frame_Dispatched : Boolean := False;
      COM_Live_Invalid_Interface_Frame_Rejected : Boolean := False;
      COM_Live_Invalid_Method_Frame_Rejected : Boolean := False;
      COM_Live_Fragment_Navigate_Dispatched : Boolean := False;
      COM_Live_Fragment_Runtime_Id_Dispatched : Boolean := False;
      COM_Live_Interface_Method_Mismatch_Rejected : Boolean := False;
      Focus_Gate : A11y.Native_Callbacks.Callback_Gate;
      Focus_Dispatcher : A11y.Dispatchers.Immediate_Dispatcher;
      Focus_Node : constant Probe_Focus_Node :=
        (Node => Root,
         State_Set =>
           A11y.States.With_State
             (A11y.States.With_State
                (A11y.States.Empty_State_Set, A11y.States.Focusable),
              A11y.States.Focused));
      Focus_Action_Provider : Probe_Focus_Action_Provider;
      Focus_Object : A11y.Native_Object_Caches.Native_Object_Id :=
        A11y.Native_Object_Caches.No_Object;
      Focus_Query_Result : A11y.Native_Focus_Calls.Native_Focus_Result;
      Focus_Action_Result : A11y.Actions.Action_Result;
      Native_Focus_Query_Dispatched : Boolean := False;
      Native_Focus_Query_Payload_Preserved : Boolean := False;
      Native_Set_Focus_Dispatched : Boolean := False;
      Native_Set_Focus_Payload_Preserved : Boolean := False;

      function Probe_Completed return Boolean is
        (Started
         and then Prepared_OK
         and then Report.Envelope_Valid
         and then Report.Native_Object_Resolved
         and then Report.Publishable
         and then Native_Provider_Created
         and then Native_Call_Admitted
         and then Native_Call_Completed
         and then Native_Call_Drained
         and then Host_Window_Bound
         and then Host_Window_Component = 17
         and then COM_VTable_Descriptor_Built
         and then COM_VTable_QueryInterface_Planned
         and then COM_VTable_Frame_Planned
         and then COM_Object_Token_Exported
         and then COM_Object_Token_Resolved
         and then COM_Object_Token_Released
         and then COM_Object_Token_Not_Reused
         and then COM_Live_Interface_Queried
         and then COM_Live_Interface_Retained
         and then COM_Live_Interface_Released
         and then COM_Live_Released_Interface_Rejected
         and then COM_Live_Interface_Dispatched
         and then COM_Live_Interface_Frame_Dispatched
         and then COM_Live_Invalid_Interface_Frame_Rejected
         and then COM_Live_Invalid_Method_Frame_Rejected
         and then COM_Live_Fragment_Navigate_Dispatched
         and then COM_Live_Fragment_Runtime_Id_Dispatched
         and then COM_Live_Interface_Method_Mismatch_Rejected
         and then Boundary_Query_Dispatched
         and then Automation_Id_Dispatched
         and then Automation_Id_Payload_Preserved
         and then Action_Discovery_Dispatched
         and then Action_Payload_Preserved
         and then Action_Request_Dispatched
         and then Action_Request_Payload_Preserved
         and then Text_Range_Dispatched
         and then Text_Range_Payload_Preserved
         and then Text_Edit_Dispatched
         and then Text_Edit_Payload_Preserved
         and then Text_Delete_Dispatched
         and then Text_Delete_Payload_Preserved
         and then Text_Replace_Dispatched
         and then Text_Replace_Payload_Preserved
         and then Text_Set_Dispatched
         and then Text_Set_Payload_Preserved
         and then Table_Current_Cell_Dispatched
         and then Table_Current_Cell_Payload_Preserved
         and then Table_Sort_Order_Dispatched
         and then Table_Sort_Order_Payload_Preserved
         and then Table_Sort_Key_Dispatched
         and then Table_Sort_Key_Payload_Preserved
         and then Value_Current_Dispatched
         and then Value_Current_Payload_Preserved
         and then Value_Set_Dispatched
         and then Value_Set_Payload_Preserved
         and then Selection_Count_Dispatched
         and then Selection_Count_Payload_Preserved
         and then Selection_Item_Dispatched
         and then Selection_Item_Payload_Preserved
         and then Selection_Request_Dispatched
         and then Selection_Request_Payload_Preserved
         and then Selection_Select_All_Dispatched
         and then Selection_Select_All_Payload_Preserved
         and then Selection_Clear_Dispatched
         and then Selection_Clear_Payload_Preserved
         and then Relation_Target_Dispatched
         and then Relation_Target_Payload_Preserved
         and then Document_Title_Dispatched
         and then Document_Title_Payload_Preserved
         and then Document_Heading_Dispatched
         and then Document_Heading_Payload_Preserved
         and then Image_Description_Dispatched
         and then Image_Description_Payload_Preserved
         and then Image_Size_Dispatched
         and then Image_Size_Payload_Preserved
         and then Live_Setting_Dispatched
         and then Live_Setting_Payload_Preserved
         and then Live_Atomic_Dispatched
         and then Live_Atomic_Payload_Preserved
         and then Surface_Kind_Dispatched
         and then Surface_Kind_Payload_Preserved
         and then Surface_Active_Dispatched
         and then Surface_Active_Payload_Preserved
         and then Native_Focus_Query_Dispatched
         and then Native_Focus_Query_Payload_Preserved
         and then Native_Set_Focus_Dispatched
         and then Native_Set_Focus_Payload_Preserved
         and then Missing_Identity_Rejected
         and then Mismatched_Identity_Rejected
         and then Malformed_Identity_Rejected
         and then Text_Payload_Limit_Rejected
         and then Boundary_Status = A11y.Results.Success
         and then Report.Status = A11y.Results.Success);

      function Failure_Stage return String is
      begin
         if not Started then
            return "runtime_start";
         elsif not Prepared_OK then
            return "event_preparation";
         elsif not Report.Envelope_Valid then
            return "event_envelope";
         elsif not Report.Native_Object_Resolved then
            return "native_object_resolution";
         elsif not Report.Publishable then
            return "event_publishable";
         elsif not Native_Provider_Created then
            return "provider_creation";
         elsif not Host_Window_Bound then
            return "host_window_binding";
         elsif not COM_VTable_Descriptor_Built then
            return "com_vtable_descriptor";
         elsif not COM_VTable_QueryInterface_Planned then
            return "com_vtable_query_interface";
         elsif not COM_VTable_Frame_Planned then
            return "com_vtable_frame";
         elsif not COM_Object_Token_Exported then
            return "com_object_token_export";
         elsif not COM_Object_Token_Resolved then
            return "com_object_token_resolve";
         elsif not COM_Object_Token_Released then
            return "com_object_token_release";
         elsif not COM_Object_Token_Not_Reused then
            return "com_object_token_reuse";
         elsif not COM_Live_Interface_Queried then
            return "com_live_interface_query";
         elsif not COM_Live_Interface_Retained then
            return "com_live_interface_retain";
         elsif not COM_Live_Interface_Released then
            return "com_live_interface_release";
         elsif not COM_Live_Released_Interface_Rejected then
            return "com_live_released_interface_rejection";
         elsif not COM_Live_Interface_Dispatched then
            return "com_live_interface_dispatch";
         elsif not COM_Live_Interface_Frame_Dispatched then
            return "com_live_interface_frame_dispatch";
         elsif not COM_Live_Invalid_Interface_Frame_Rejected then
            return "com_live_invalid_interface_frame";
         elsif not COM_Live_Invalid_Method_Frame_Rejected then
            return "com_live_invalid_method_frame";
         elsif not COM_Live_Fragment_Navigate_Dispatched then
            return "com_live_fragment_navigate";
         elsif not COM_Live_Fragment_Runtime_Id_Dispatched then
            return "com_live_fragment_runtime_id";
         elsif not COM_Live_Interface_Method_Mismatch_Rejected then
            return "com_live_interface_method_mismatch";
         elsif not Native_Call_Admitted then
            return "native_call_admission";
         elsif not Boundary_Query_Dispatched then
            return "boundary_query";
         elsif not Automation_Id_Dispatched then
            return "automation_id";
         elsif not Automation_Id_Payload_Preserved then
            return "automation_id_payload";
         elsif not Action_Discovery_Dispatched then
            return "action_discovery";
         elsif not Action_Payload_Preserved then
            return "action_payload";
         elsif not Action_Request_Dispatched then
            return "action_request";
         elsif not Action_Request_Payload_Preserved then
            return "action_request_payload";
         elsif not Text_Range_Dispatched then
            return "text_range";
         elsif not Text_Range_Payload_Preserved then
            return "text_range_payload";
         elsif not Text_Edit_Dispatched then
            return "text_edit";
         elsif not Text_Edit_Payload_Preserved then
            return "text_edit_payload";
         elsif not Text_Delete_Dispatched then
            return "text_delete";
         elsif not Text_Delete_Payload_Preserved then
            return "text_delete_payload";
         elsif not Text_Replace_Dispatched then
            return "text_replace";
         elsif not Text_Replace_Payload_Preserved then
            return "text_replace_payload";
         elsif not Text_Set_Dispatched then
            return "text_set";
         elsif not Text_Set_Payload_Preserved then
            return "text_set_payload";
         elsif not Table_Current_Cell_Dispatched then
            return "table_current_cell";
         elsif not Table_Current_Cell_Payload_Preserved then
            return "table_current_cell_payload";
         elsif not Table_Sort_Order_Dispatched then
            return "table_sort_order";
         elsif not Table_Sort_Order_Payload_Preserved then
            return "table_sort_order_payload";
         elsif not Table_Sort_Key_Dispatched then
            return "table_sort_key";
         elsif not Table_Sort_Key_Payload_Preserved then
            return "table_sort_key_payload";
         elsif not Value_Current_Dispatched then
            return "value_current";
         elsif not Value_Current_Payload_Preserved then
            return "value_current_payload";
         elsif not Value_Set_Dispatched then
            return "value_set";
         elsif not Value_Set_Payload_Preserved then
            return "value_set_payload";
         elsif not Selection_Count_Dispatched then
            return "selection_count";
         elsif not Selection_Count_Payload_Preserved then
            return "selection_count_payload";
         elsif not Selection_Item_Dispatched then
            return "selection_item";
         elsif not Selection_Item_Payload_Preserved then
            return "selection_item_payload";
         elsif not Selection_Request_Dispatched then
            return "selection_request";
         elsif not Selection_Request_Payload_Preserved then
            return "selection_request_payload";
         elsif not Selection_Select_All_Dispatched then
            return "selection_select_all";
         elsif not Selection_Select_All_Payload_Preserved then
            return "selection_select_all_payload";
         elsif not Selection_Clear_Dispatched then
            return "selection_clear";
         elsif not Selection_Clear_Payload_Preserved then
            return "selection_clear_payload";
         elsif not Relation_Target_Dispatched then
            return "relation_target";
         elsif not Relation_Target_Payload_Preserved then
            return "relation_target_payload";
         elsif not Document_Title_Dispatched then
            return "document_title";
         elsif not Document_Title_Payload_Preserved then
            return "document_title_payload";
         elsif not Document_Heading_Dispatched then
            return "document_heading";
         elsif not Document_Heading_Payload_Preserved then
            return "document_heading_payload";
         elsif not Image_Description_Dispatched then
            return "image_description";
         elsif not Image_Description_Payload_Preserved then
            return "image_description_payload";
         elsif not Image_Size_Dispatched then
            return "image_size";
         elsif not Image_Size_Payload_Preserved then
            return "image_size_payload";
         elsif not Live_Setting_Dispatched then
            return "live_setting";
         elsif not Live_Setting_Payload_Preserved then
            return "live_setting_payload";
         elsif not Live_Atomic_Dispatched then
            return "live_atomic";
         elsif not Live_Atomic_Payload_Preserved then
            return "live_atomic_payload";
         elsif not Surface_Kind_Dispatched then
            return "surface_kind";
         elsif not Surface_Kind_Payload_Preserved then
            return "surface_kind_payload";
         elsif not Surface_Active_Dispatched then
            return "surface_active";
         elsif not Surface_Active_Payload_Preserved then
            return "surface_active_payload";
         elsif not Native_Focus_Query_Dispatched then
            return "native_focus_query";
         elsif not Native_Focus_Query_Payload_Preserved then
            return "native_focus_query_payload";
         elsif not Native_Set_Focus_Dispatched then
            return "native_set_focus";
         elsif not Native_Set_Focus_Payload_Preserved then
            return "native_set_focus_payload";
         elsif not Missing_Identity_Rejected then
            return "missing_identity";
         elsif not Mismatched_Identity_Rejected then
            return "mismatched_identity";
         elsif not Malformed_Identity_Rejected then
            return "malformed_identity";
         elsif not Text_Payload_Limit_Rejected then
            return "text_payload_limit";
         elsif not Native_Call_Completed then
            return "native_call_completion";
         elsif not Native_Call_Drained then
            return "native_call_drain";
         elsif Boundary_Status /= A11y.Results.Success then
            return "boundary_status";
         elsif Report.Status /= A11y.Results.Success then
            return "event_status";
         else
            return "none";
         end if;
      end Failure_Stage;
   begin
      A11y.Native_Runtimes.Start (Runtime, Result);
      Started := A11y.Results.Succeeded (Result);
      if Started then
         A11y.Native_Runtimes.Prepare_Event
           (Runtime, Event, Prepared, Result);
         Prepared_OK := A11y.Results.Succeeded (Result);
      end if;

      if Prepared_OK then
         A11y.Windows_Backend.UIA_Events.Build_Prepared_Event_With_Report
           (Prepared, Emission, Report);
      else
         Report.Status := Result.Status;
      end if;

      if Started then
         A11y.Windows_Backend.UIA_Com_Providers.Initialize
           (Provider,
            A11y.Native_Runtimes.Session (Runtime),
            Root,
            Root,
            Result);
         Native_Provider_Created := A11y.Results.Succeeded (Result);
      end if;

      if Native_Provider_Created then
         A11y.Windows_Backend.UIA_Com_Providers.Bind_Host_Window_Root
           (Provider, 17, Result);
         Provider_Export :=
           A11y.Windows_Backend.UIA_Com_Providers.Export_Descriptor
             (Provider);
         Host_Window_Bound :=
           A11y.Results.Succeeded (Result)
           and then Provider_Export.Exportable
           and then Provider_Export.Host_Window_Bound
           and then Provider_Export.Host_Window_Component = 17;
         Host_Window_Component := Provider_Export.Host_Window_Component;
      end if;

      if Host_Window_Bound then
         A11y.Windows_Backend.UIA_Provider_Registry.Ensure_Provider
           (Provider_Registry,
            A11y.Native_Runtimes.Session (Runtime),
            Root,
            Root,
            Provider_Id,
            Result);
         Export_Table :=
           A11y.Windows_Backend.UIA_COM_Exports.Build_Export_Table
             (Provider_Id, Provider_Export);
         Object_Descriptor :=
           A11y.Windows_Backend.UIA_COM_VTables.Build_Object_Descriptor
             (Export_Table);
         COM_VTable_Descriptor_Built :=
           A11y.Results.Succeeded (Result)
           and then Object_Descriptor.Exportable
           and then Object_Descriptor.Controlling_IUnknown_Stable
           and then Object_Descriptor.Host_Window_Bound
           and then Object_Descriptor.Host_Window_Component = 17
           and then A11y.Windows_Backend.UIA_COM_VTables.Interface_Supported
             (Object_Descriptor,
              A11y.Windows_Backend.UIA_Com_Providers.IUnknown_Interface)
           and then A11y.Windows_Backend.UIA_COM_VTables.Interface_Supported
             (Object_Descriptor,
              A11y.Windows_Backend.UIA_Com_Providers
                .Raw_Element_Provider_Simple)
           and then A11y.Windows_Backend.UIA_COM_VTables.Interface_Supported
             (Object_Descriptor,
              A11y.Windows_Backend.UIA_Com_Providers
                .Raw_Element_Provider_Fragment_Root);

         Query_Plan :=
           A11y.Windows_Backend.UIA_COM_VTables.Query_Interface
             (Object_Descriptor,
              A11y.Windows_Backend.UIA_Com_Providers
                .Raw_Element_Provider_Fragment);
         COM_VTable_QueryInterface_Planned :=
           Query_Plan.Supported
           and then Query_Plan.Status = A11y.Results.Success
           and then Query_Plan.ABI_HResult_Code = 16#0000_0000#;

         Frame_Plan :=
           A11y.Windows_Backend.UIA_COM_VTables.Frame_For
             (Object_Descriptor,
              A11y.Windows_Backend.UIA_ABI_Surface
                .Simple_Get_Property_Value);
         COM_VTable_Frame_Planned :=
           Frame_Plan.Supported
           and then Frame_Plan.Status = A11y.Results.Success
           and then Frame_Plan.Frame.Method_Code =
             A11y.Windows_Backend.UIA_COM_Exports.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Simple_Get_Property_Value);

         if COM_VTable_Frame_Planned then
            A11y.Windows_Backend.UIA_COM_Object_Exports.Export_Object
              (Object_Export_Table, Object_Descriptor, Object_Export);
            COM_Object_Token_Exported :=
              Object_Export.Exported
              and then Object_Export.Status = A11y.Results.Success
              and then A11y.Windows_Backend.UIA_COM_Object_Exports.Is_Valid
                (Object_Export.Token);

            A11y.Windows_Backend.UIA_COM_Object_Exports.Resolve_Object
              (Object_Export_Table,
               Object_Export.Token,
               A11y.Native_Runtimes.Session (Runtime),
               Provider_Id,
               Object_Resolve);
            COM_Object_Token_Resolved :=
              COM_Object_Token_Exported
              and then Object_Resolve.Found
              and then Object_Resolve.Status = A11y.Results.Success
              and then Object_Resolve.Descriptor.Provider = Provider_Id
              and then Object_Resolve.Descriptor.Session =
                A11y.Native_Runtimes.Session (Runtime);

            A11y.Windows_Backend.UIA_COM_Object_Exports.Release_Object
              (Object_Export_Table, Object_Export.Token, Object_Release);
            COM_Object_Token_Released :=
              COM_Object_Token_Resolved
              and then Object_Release.Released
              and then Object_Release.Status = A11y.Results.Success
              and then Object_Release.Tombstone_Added;

            A11y.Windows_Backend.UIA_COM_Object_Exports.Export_Object
              (Object_Export_Table, Object_Descriptor, Second_Object_Export);
            COM_Object_Token_Not_Reused :=
              COM_Object_Token_Released
              and then Second_Object_Export.Exported
              and then Second_Object_Export.Status = A11y.Results.Success
              and then
                A11y.Windows_Backend.UIA_COM_Object_Exports.To_Natural
                  (Second_Object_Export.Token)
                >
                A11y.Windows_Backend.UIA_COM_Object_Exports.To_Natural
                  (Object_Export.Token);

            A11y.Windows_Backend.UIA_COM_Live_Exports.Query_Interface
              (Object_Export_Table,
               Second_Object_Export.Token,
               A11y.Native_Runtimes.Session (Runtime),
               Provider_Id,
               A11y.Windows_Backend.UIA_Com_Providers
                 .Raw_Element_Provider_Simple,
               Live_Interface_Query);
            Live_Interface := Live_Interface_Query.Reference;
            COM_Live_Interface_Queried :=
              COM_Object_Token_Not_Reused
              and then Live_Interface_Query.Object_Resolved
              and then Live_Interface_Query.Query.Supported
              and then Live_Interface.Present
              and then Live_Interface.Reference_Count = 1
              and then not Live_Interface.Released
              and then Live_Interface.Kind =
                A11y.Windows_Backend.UIA_Com_Providers
                  .Raw_Element_Provider_Simple
              and then Live_Interface.Provider = Provider_Id
              and then Live_Interface.Node = Root
              and then Live_Interface_Query.ABI_HResult_Code = 16#0000_0000#;

            A11y.Windows_Backend.UIA_COM_Live_Exports.Add_Ref
              (Live_Interface, Live_Interface_Add_Ref);
            COM_Live_Interface_Retained :=
              COM_Live_Interface_Queried
              and then Live_Interface_Add_Ref.Reference_Present
              and then Live_Interface_Add_Ref.Count_Before = 1
              and then Live_Interface_Add_Ref.Count_After = 2
              and then Live_Interface_Add_Ref.Status = A11y.Results.Success
              and then Live_Interface.Reference_Count = 2
              and then not Live_Interface.Released;

            Released_Live_Interface := Live_Interface;
            A11y.Windows_Backend.UIA_COM_Live_Exports.Release
              (Released_Live_Interface, Live_Interface_Release);
            A11y.Windows_Backend.UIA_COM_Live_Exports.Release
              (Released_Live_Interface, Live_Interface_Final_Release);
            COM_Live_Interface_Released :=
              COM_Live_Interface_Retained
              and then Live_Interface_Release.Reference_Present
              and then Live_Interface_Release.Count_Before = 2
              and then Live_Interface_Release.Count_After = 1
              and then not Live_Interface_Release.Reference_Released_After
              and then Live_Interface_Final_Release.Reference_Present
              and then Live_Interface_Final_Release.Count_Before = 1
              and then Live_Interface_Final_Release.Count_After = 0
              and then Live_Interface_Final_Release.Reference_Released_After
              and then Released_Live_Interface.Released;
         end if;
      end if;

      if Host_Window_Bound then
         A11y.Windows_Backend.UIA_Com_Providers.Begin_Native_Call
           (Provider,
            A11y.Windows_Backend.UIA_Com_Providers.Raw_Element_Provider_Simple,
            Context,
            Result);
         Call_Snapshot :=
           A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Context);
         Native_Call_Admitted :=
           A11y.Results.Succeeded (Result) and then Call_Snapshot.Active;
      end if;

      if Native_Call_Admitted then
         Native_Component :=
           A11y.Native_Identity.Runtime_Identifier_Component
             (A11y.Native_Runtimes.Session (Runtime), Root, Result);

         Snapshots.all.Properties.Id := Root;
         Snapshots.all.Properties.Root := Root;
         Snapshots.all.Fragment.Session :=
           A11y.Native_Runtimes.Session (Runtime);
         A11y.Trees.Set_Root (Snapshots.all.Properties.Tree, Root, Result);
         A11y.Trees.Set_Root (Snapshots.all.Fragment.Tree, Root, Result);
         A11y.Trees.Attach
           (Snapshots.all.Fragment.Tree, Root, Fragment_Child, Result);
         Snapshots.all.Fragment.Fragment_Root := Root;
         Snapshots.all.Fragment.Node := Root;
         Snapshots.all.Properties.Role := A11y.Roles.Button;
         Snapshots.all.Properties.Name :=
           A11y.Properties.Present ("Probe Button");
         Snapshots.all.Properties.Automation_Id :=
           A11y.Properties.Present ("probe-button");

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Property_Value;
         Boundary_Request.Property := A11y.Windows_Backend.UIA_Properties.Name;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Boundary_Status := Boundary_Reply.Status;
         Boundary_Query_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Status = A11y.Results.Success;

         Boundary_Request.Property :=
           A11y.Windows_Backend.UIA_Properties.Automation_Id;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Automation_Id_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Property_String;
         Automation_Id_Payload_Preserved :=
           Automation_Id_Dispatched
           and then To_String (Boundary_Reply.Payload.Text) = "probe-button";

         Boundary_Reply :=
           A11y.Windows_Backend.UIA_COM_Live_Exports
             .Dispatch_Interface_Method
               (Object_Export_Table,
                Live_Interface,
                A11y.Windows_Backend.UIA_ABI_Surface
                  .Simple_Get_Property_Value,
                Provider_Registry,
                Snapshots.all,
                Live_Interface_Dispatch);
         COM_Live_Interface_Dispatched :=
           COM_Live_Interface_Queried
           and then Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Live_Interface_Dispatch.Object_Resolved
           and then Live_Interface_Dispatch.Interface_Accepted
           and then Live_Interface_Dispatch.Method_Allowed_For_Interface
           and then Live_Interface_Dispatch.Frame_Prepared
           and then Live_Interface_Dispatch.Callback_Dispatched
           and then Live_Interface_Dispatch.Callback.Invoke
             .Registered_Dispatched
           and then Live_Interface_Dispatch.ABI_HResult_Code = 16#0000_0000#;

         Boundary_Reply :=
           A11y.Windows_Backend.UIA_COM_Live_Exports
             .Dispatch_Interface_Method
               (Object_Export_Table,
                Released_Live_Interface,
                A11y.Windows_Backend.UIA_ABI_Surface
                  .Simple_Get_Property_Value,
                Provider_Registry,
                Snapshots.all,
                Released_Live_Interface_Dispatch);
         COM_Live_Released_Interface_Rejected :=
           COM_Live_Interface_Released
           and then Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
           and then Boundary_Reply.Status = A11y.Results.Node_Unavailable
           and then not Released_Live_Interface_Dispatch.Object_Resolved
           and then not Released_Live_Interface_Dispatch.Callback_Dispatched;

         Live_Interface_Frame :=
           A11y.Windows_Backend.UIA_COM_Live_Exports
             .Build_Interface_Frame
               (Live_Interface,
                A11y.Windows_Backend.UIA_ABI_Surface
                  .Simple_Get_Property_Value);
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_COM_Live_Exports
             .Dispatch_Interface_Frame
               (Object_Export_Table,
                Live_Interface_Frame,
                Provider_Registry,
                Snapshots.all,
                Live_Interface_Frame_Dispatch);
         COM_Live_Interface_Frame_Dispatched :=
           COM_Live_Interface_Dispatched
           and then Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Live_Interface_Frame_Dispatch.Session_Code_Valid
           and then Live_Interface_Frame_Dispatch.Provider_Code_Valid
           and then Live_Interface_Frame_Dispatch.Object_Token_Valid
           and then Live_Interface_Frame_Dispatch.Interface_Code_Valid
           and then Live_Interface_Frame_Dispatch.Method_Code_Valid
           and then Live_Interface_Frame_Dispatch.Reference_Queried
           and then Live_Interface_Frame_Dispatch.Dispatch.Object_Resolved
           and then Live_Interface_Frame_Dispatch.Dispatch.Interface_Accepted
           and then Live_Interface_Frame_Dispatch.Dispatch
             .Method_Allowed_For_Interface
           and then Live_Interface_Frame_Dispatch.Dispatch.Frame_Prepared
           and then Live_Interface_Frame_Dispatch.Dispatch.Callback_Dispatched
           and then Live_Interface_Frame_Dispatch.Dispatch.Callback.Invoke
             .Registered_Dispatched
           and then Live_Interface_Frame_Dispatch.ABI_HResult_Code =
             16#0000_0000#;

         Rejected_Live_Interface_Frame := Live_Interface_Frame;
         Rejected_Live_Interface_Frame.Interface_Code := 99;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_COM_Live_Exports
             .Dispatch_Interface_Frame
               (Object_Export_Table,
                Rejected_Live_Interface_Frame,
                Provider_Registry,
                Snapshots.all,
                Rejected_Live_Interface_Frame_Dispatch);
         COM_Live_Invalid_Interface_Frame_Rejected :=
           COM_Live_Interface_Frame_Dispatched
           and then Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
           and then Boundary_Reply.Status = A11y.Results.Invalid_Argument
           and then Rejected_Live_Interface_Frame_Dispatch
             .Session_Code_Valid
           and then Rejected_Live_Interface_Frame_Dispatch
             .Provider_Code_Valid
           and then Rejected_Live_Interface_Frame_Dispatch
             .Object_Token_Valid
           and then not Rejected_Live_Interface_Frame_Dispatch
             .Interface_Code_Valid
           and then not Rejected_Live_Interface_Frame_Dispatch
             .Reference_Queried;

         Rejected_Live_Interface_Frame := Live_Interface_Frame;
         Rejected_Live_Interface_Frame.Method_Code := 999;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_COM_Live_Exports
             .Dispatch_Interface_Frame
               (Object_Export_Table,
                Rejected_Live_Interface_Frame,
                Provider_Registry,
                Snapshots.all,
                Rejected_Live_Interface_Frame_Dispatch);
         COM_Live_Invalid_Method_Frame_Rejected :=
           COM_Live_Invalid_Interface_Frame_Rejected
           and then Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
           and then Boundary_Reply.Status = A11y.Results.Invalid_Argument
           and then Rejected_Live_Interface_Frame_Dispatch
             .Interface_Code_Valid
           and then not Rejected_Live_Interface_Frame_Dispatch
             .Method_Code_Valid
           and then not Rejected_Live_Interface_Frame_Dispatch
             .Reference_Queried;

         A11y.Windows_Backend.UIA_COM_Live_Exports.Query_Interface
           (Object_Export_Table,
            Second_Object_Export.Token,
            A11y.Native_Runtimes.Session (Runtime),
            Provider_Id,
            A11y.Windows_Backend.UIA_Com_Providers
              .Raw_Element_Provider_Fragment,
            Live_Fragment_Interface_Query);
         Live_Fragment_Interface :=
           Live_Fragment_Interface_Query.Reference;

         Boundary_Reply :=
           A11y.Windows_Backend.UIA_COM_Live_Exports
             .Dispatch_Interface_Method
               (Object_Export_Table,
                Live_Fragment_Interface,
                A11y.Windows_Backend.UIA_ABI_Surface.Fragment_Navigate,
                Provider_Registry,
                Snapshots.all,
                Rejected_Live_Interface_Dispatch,
                A11y.Windows_Backend.UIA_Fragments.First_Child);
         COM_Live_Fragment_Navigate_Dispatched :=
           COM_Live_Invalid_Method_Frame_Rejected
           and then Live_Fragment_Interface_Query.Object_Resolved
           and then Live_Fragment_Interface_Query.Query.Supported
           and then Live_Fragment_Interface.Present
           and then Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Fragment_Node
           and then Boundary_Reply.Payload.Node = Fragment_Child
           and then Rejected_Live_Interface_Dispatch.Object_Resolved
           and then Rejected_Live_Interface_Dispatch.Interface_Accepted
           and then Rejected_Live_Interface_Dispatch
             .Method_Allowed_For_Interface
           and then Rejected_Live_Interface_Dispatch.Frame_Prepared
           and then Rejected_Live_Interface_Dispatch.Callback_Dispatched
           and then Rejected_Live_Interface_Dispatch.Callback.Invoke
             .Registered_Dispatched;

         Live_Interface_Frame :=
           A11y.Windows_Backend.UIA_COM_Live_Exports
             .Build_Interface_Frame
               (Live_Fragment_Interface,
                A11y.Windows_Backend.UIA_ABI_Surface
                  .Fragment_Get_Runtime_Id);
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_COM_Live_Exports
             .Dispatch_Interface_Frame
               (Object_Export_Table,
                Live_Interface_Frame,
                Provider_Registry,
                Snapshots.all,
                Live_Interface_Frame_Dispatch);
         declare
            Root_Result : A11y.Results.Result;
            Node_Result : A11y.Results.Result;
            Root_Component : constant Natural :=
              A11y.Native_Identity.Runtime_Identifier_Component
                (A11y.Native_Runtimes.Session (Runtime), Root, Root_Result);
            Node_Component : constant Natural :=
              A11y.Native_Identity.Runtime_Identifier_Component
                (A11y.Native_Runtimes.Session (Runtime), Root, Node_Result);
         begin
            COM_Live_Fragment_Runtime_Id_Dispatched :=
              COM_Live_Fragment_Navigate_Dispatched
              and then A11y.Results.Succeeded (Root_Result)
              and then A11y.Results.Succeeded (Node_Result)
              and then Boundary_Reply.Kind =
                A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
              and then Boundary_Reply.HResult =
                A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
              and then Boundary_Reply.Status = A11y.Results.Success
              and then Boundary_Reply.Routed =
                A11y.Windows_Backend.UIA_Request_Router.Runtime_Id
              and then Boundary_Reply.Payload.Id.Session_Component =
                A11y.Native_Identity.To_Natural
                  (A11y.Native_Runtimes.Session (Runtime))
              and then Boundary_Reply.Payload.Id.Root_Component =
                Root_Component
              and then Boundary_Reply.Payload.Id.Node_Component =
                Node_Component
              and then Live_Interface_Frame_Dispatch.Session_Code_Valid
              and then Live_Interface_Frame_Dispatch.Provider_Code_Valid
              and then Live_Interface_Frame_Dispatch.Object_Token_Valid
              and then Live_Interface_Frame_Dispatch.Interface_Code_Valid
              and then Live_Interface_Frame_Dispatch.Method_Code_Valid
              and then Live_Interface_Frame_Dispatch.Direction_Code_Valid
              and then Live_Interface_Frame_Dispatch.Reference_Queried
              and then Live_Interface_Frame_Dispatch.Dispatch
                .Callback_Dispatched;
         end;

         Boundary_Reply :=
           A11y.Windows_Backend.UIA_COM_Live_Exports
             .Dispatch_Interface_Method
               (Object_Export_Table,
                Live_Fragment_Interface,
                A11y.Windows_Backend.UIA_ABI_Surface
                  .Simple_Get_Property_Value,
                Provider_Registry,
                Snapshots.all,
                Rejected_Live_Interface_Dispatch);
         COM_Live_Interface_Method_Mismatch_Rejected :=
           COM_Live_Invalid_Method_Frame_Rejected
           and then Live_Fragment_Interface_Query.Object_Resolved
           and then Live_Fragment_Interface_Query.Query.Supported
           and then Live_Fragment_Interface.Present
           and then Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary
               .Provider_Not_Supported
           and then Boundary_Reply.Status =
             A11y.Results.Unsupported_Capability
           and then Rejected_Live_Interface_Dispatch.Object_Resolved
           and then Rejected_Live_Interface_Dispatch.Interface_Accepted
           and then not Rejected_Live_Interface_Dispatch
             .Method_Allowed_For_Interface
           and then not Rejected_Live_Interface_Dispatch
             .Callback_Dispatched;

         Snapshots.all.Action_Node := Root;
         Snapshots.all.Action_Root := Root;
         Snapshots.all.Actions :=
           A11y.Actions.With_Action
             (A11y.Actions.With_Action
                (A11y.Actions.Empty_Action_Set, A11y.Actions.Press),
              A11y.Actions.Toggle);
         A11y.Trees.Set_Root (Snapshots.all.Action_Tree, Root, Result);

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Pattern_Provider;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Action_Discovery_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Pattern_Set;
         Action_Payload_Preserved :=
           Action_Discovery_Dispatched
           and then Boundary_Reply.Payload.Patterns
             (A11y.Windows_Backend.UIA_Actions.Invoke)
           and then Boundary_Reply.Payload.Patterns
             (A11y.Windows_Backend.UIA_Actions.Toggle);

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Invoke_Action;
         Boundary_Request.Action := A11y.Actions.Toggle;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Action_Request_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Action_Request;
         Action_Request_Payload_Preserved :=
           Action_Request_Dispatched
           and then Boundary_Reply.Payload.Requested_Action =
             A11y.Actions.Toggle;

         Snapshots.all.Text.Id := Root;
         Snapshots.all.Text.Root := Root;
         Snapshots.all.Text.Content :=
           To_Unbounded_Wide_Wide_String ("Probe Text");

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Text;
         Boundary_Request.Text :=
           A11y.Windows_Backend.UIA_Text.Text_Range;
         Boundary_Request.Index := 1;
         Boundary_Request.Count := 5;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Text_Range_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Text_Wide_Text;
         Text_Range_Payload_Preserved :=
           Text_Range_Dispatched
           and then To_Wide_Wide_String (Boundary_Reply.Payload.Wide_Text) =
             "Probe";

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Text_Edit;
         Boundary_Request.Text_Edit := A11y.Text.Insert_Text;
         Boundary_Request.Index := 2;
         Boundary_Request.Count := 0;
         Boundary_Request.Replacement :=
           To_Unbounded_Wide_Wide_String ("X");
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Text_Edit_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Text_Edit_Request;
         Text_Edit_Payload_Preserved :=
           Text_Edit_Dispatched
           and then Boundary_Reply.Payload.Requested_Edit.Kind =
             A11y.Text.Insert_Text
           and then A11y.Text.Index
             (A11y.Text.First (Boundary_Reply.Payload.Requested_Edit.Span)) = 1
           and then A11y.Text.Length
             (Boundary_Reply.Payload.Requested_Edit.Span) = 0
           and then To_Wide_Wide_String
             (Boundary_Reply.Payload.Requested_Edit.Text) = "X";

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Text_Edit;
         Boundary_Request.Text_Edit := A11y.Text.Delete_Text;
         Boundary_Request.Index := 3;
         Boundary_Request.Count := 2;
         Boundary_Request.Replacement :=
           Null_Unbounded_Wide_Wide_String;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Text_Delete_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Text_Edit_Request;
         Text_Delete_Payload_Preserved :=
           Text_Delete_Dispatched
           and then Boundary_Reply.Payload.Requested_Edit.Kind =
             A11y.Text.Delete_Text
           and then A11y.Text.Index
             (A11y.Text.First (Boundary_Reply.Payload.Requested_Edit.Span)) = 2
           and then A11y.Text.Length
             (Boundary_Reply.Payload.Requested_Edit.Span) = 2
           and then Length (Boundary_Reply.Payload.Requested_Edit.Text) = 0;

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Text_Edit;
         Boundary_Request.Text_Edit := A11y.Text.Replace_Text;
         Boundary_Request.Index := 4;
         Boundary_Request.Count := 3;
         Boundary_Request.Replacement :=
           To_Unbounded_Wide_Wide_String ("XYZ");
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Text_Replace_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Text_Edit_Request;
         Text_Replace_Payload_Preserved :=
           Text_Replace_Dispatched
           and then Boundary_Reply.Payload.Requested_Edit.Kind =
             A11y.Text.Replace_Text
           and then A11y.Text.Index
             (A11y.Text.First (Boundary_Reply.Payload.Requested_Edit.Span)) = 3
           and then A11y.Text.Length
             (Boundary_Reply.Payload.Requested_Edit.Span) = 3
           and then To_Wide_Wide_String
             (Boundary_Reply.Payload.Requested_Edit.Text) = "XYZ";

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Text_Edit;
         Boundary_Request.Text_Edit := A11y.Text.Set_Text;
         Boundary_Request.Index := 1;
         Boundary_Request.Count := 0;
         Boundary_Request.Replacement :=
           To_Unbounded_Wide_Wide_String ("Reset");
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Text_Set_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Text_Edit_Request;
         Text_Set_Payload_Preserved :=
           Text_Set_Dispatched
           and then Boundary_Reply.Payload.Requested_Edit.Kind =
             A11y.Text.Set_Text
           and then A11y.Text.Length
             (Boundary_Reply.Payload.Requested_Edit.Span) = 0
           and then To_Wide_Wide_String
             (Boundary_Reply.Payload.Requested_Edit.Text) = "Reset";

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Property_Value;
         Boundary_Request.Property := A11y.Windows_Backend.UIA_Properties.Name;
         Boundary_Request.Has_Native_Identity := False;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Missing_Identity_Rejected :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.E_INVALIDARG
           and then Boundary_Reply.Status = A11y.Results.Invalid_Argument;

         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component :=
           A11y.Native_Identity.Runtime_Identifier_Component
             (A11y.Native_Runtimes.Session (Runtime), Table_Cell, Result);
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Mismatched_Identity_Rejected :=
           A11y.Results.Succeeded (Result)
           and then Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary
               .UIA_E_ELEMENTNOTAVAILABLE
           and then Boundary_Reply.Status = A11y.Results.Node_Unavailable;

         Boundary_Request.Native_Node_Component := 0;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Malformed_Identity_Rejected :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary
               .UIA_E_ELEMENTNOTAVAILABLE
           and then Boundary_Reply.Status = A11y.Results.Node_Unavailable;

         A11y.Resource_Limits.Set_Limit
           (Snapshots.all.Limits,
            A11y.Resource_Limits.Native_String_Size,
            1,
            Result);
         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Text_Edit;
         Boundary_Request.Text_Edit := A11y.Text.Insert_Text;
         Boundary_Request.Index := 1;
         Boundary_Request.Count := 0;
         Boundary_Request.Replacement := To_Unbounded_Wide_Wide_String ("XX");
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Text_Payload_Limit_Rejected :=
           A11y.Results.Succeeded (Result)
           and then Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.E_OUTOFMEMORY
           and then Boundary_Reply.Status = A11y.Results.Resource_Limit;
         Snapshots.all.Limits := A11y.Resource_Limits.Default_Config;
         Boundary_Request.Replacement := Null_Unbounded_Wide_Wide_String;

         Snapshots.all.Table.Id := Root;
         Snapshots.all.Table.Root := Root;
         A11y.Tables.Configure
           (Snapshots.all.Table.Table, Rows => 3, Columns => 5);
         A11y.Tables.Add_Cell
           (Snapshots.all.Table.Table,
            Table_Cell,
            Row => 1,
            Column => 2,
            Row_Span => 2,
            Column_Span => 3,
            Result => Result);
         A11y.Tables.Set_Current_Cell
           (Snapshots.all.Table.Table, Table_Cell, Result);
         A11y.Tables.Set_Sort
           (Snapshots.all.Table.Table,
            Table_Cell,
            A11y.Tables.Descending,
            Result);

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Table;
         Boundary_Request.Table :=
           A11y.Windows_Backend.UIA_Table.Current_Cell;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Table_Current_Cell_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Table_Node;
         Table_Current_Cell_Payload_Preserved :=
           Table_Current_Cell_Dispatched
           and then Boundary_Reply.Payload.Node = Table_Cell;

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Table;
         Boundary_Request.Table :=
           A11y.Windows_Backend.UIA_Table.Sort_Order;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Table_Sort_Order_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Table_UInt32;
         Table_Sort_Order_Payload_Preserved :=
           Table_Sort_Order_Dispatched
           and then Boundary_Reply.Payload.UInt32 =
             A11y.Tables.Sort_Order'Pos (A11y.Tables.Descending);

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Table;
         Boundary_Request.Table :=
           A11y.Windows_Backend.UIA_Table.Sort_Key;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Table_Sort_Key_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Table_Node;
         Table_Sort_Key_Payload_Preserved :=
           Table_Sort_Key_Dispatched
           and then Boundary_Reply.Payload.Node = Table_Cell;

         Snapshots.all.Value.Id := Root;
         Snapshots.all.Value.Root := Root;
         Snapshots.all.Value.Metadata.Current := A11y.Values.Floating (5.0);
         Snapshots.all.Value.Metadata.Minimum := A11y.Values.Floating (0.0);
         Snapshots.all.Value.Metadata.Maximum := A11y.Values.Floating (10.0);
         Snapshots.all.Value.Metadata.Small_Increment :=
           A11y.Values.Floating (1.0);
         Snapshots.all.Value.Metadata.Mode := A11y.Values.Writable;

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Value;
         Boundary_Request.Value :=
           A11y.Windows_Backend.UIA_Values.Current_Value;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Value_Current_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Value_Float;
         Value_Current_Payload_Preserved :=
           Value_Current_Dispatched
           and then Boundary_Reply.Payload.Float_Item = 5.0;

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Set_Value;
         Boundary_Request.Requested_Value := A11y.Values.Floating (6.0);
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Value_Set_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Value_Set_Request;
         Value_Set_Payload_Preserved :=
           Value_Set_Dispatched
           and then A11y.Values.Equal
             (Boundary_Reply.Payload.Requested_Value,
              A11y.Values.Floating (6.0));

         Snapshots.all.Selection.Root := Root;
         Snapshots.all.Selection.Item := Selection_Item;
         Snapshots.all.Selection.Items.Append (Selection_Item);
         A11y.Selection.Configure
           (Snapshots.all.Selection.Selection, A11y.Selection.Multiple);
         A11y.Selection.Select_Item
           (Snapshots.all.Selection.Selection, Selection_Item, Result);
         Selection_Component :=
           A11y.Native_Identity.Runtime_Identifier_Component
             (A11y.Native_Runtimes.Session (Runtime),
              Selection_Item,
              Result);

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Selection;
         Boundary_Request.Selection :=
           A11y.Windows_Backend.UIA_Selection.Selected_Count;
         Boundary_Request.Index := 1;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Selection_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Selection_Count_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Selection_UInt32;
         Selection_Count_Payload_Preserved :=
           Selection_Count_Dispatched
           and then Boundary_Reply.Payload.UInt32 = 1;

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Selection;
         Boundary_Request.Selection :=
           A11y.Windows_Backend.UIA_Selection.Selected_Item;
         Boundary_Request.Index := 1;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Selection_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Selection_Item_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Selection_Node;
         Selection_Item_Payload_Preserved :=
           Selection_Item_Dispatched
           and then Boundary_Reply.Payload.Node = Selection_Item;

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Set_Selection;
         Boundary_Request.Selection_Request :=
           A11y.Windows_Backend.UIA_Selection.Toggle_Item;
         Boundary_Request.Selection_Target := Selection_Item;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Selection_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Selection_Request_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Selection_Request_Reply;
         Selection_Request_Payload_Preserved :=
           Selection_Request_Dispatched
           and then Boundary_Reply.Payload.Selection_Target = Selection_Item
           and then Boundary_Reply.Payload.Selection_Request =
             A11y.Windows_Backend.UIA_Selection.Toggle_Item;

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Set_Selection;
         Boundary_Request.Selection_Request :=
           A11y.Windows_Backend.UIA_Selection.Select_All;
         Boundary_Request.Selection_Target := A11y.Node_Ids.No_Node;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Selection_Select_All_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Selection_Request_Reply;
         Selection_Select_All_Payload_Preserved :=
           Selection_Select_All_Dispatched
           and then Boundary_Reply.Payload.Selection_Target =
             A11y.Node_Ids.No_Node
           and then Boundary_Reply.Payload.Selection_Request =
             A11y.Windows_Backend.UIA_Selection.Select_All;

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Set_Selection;
         Boundary_Request.Selection_Request :=
           A11y.Windows_Backend.UIA_Selection.Clear_Selection;
         Boundary_Request.Selection_Target := A11y.Node_Ids.No_Node;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Selection_Clear_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Selection_Request_Reply;
         Selection_Clear_Payload_Preserved :=
           Selection_Clear_Dispatched
           and then Boundary_Reply.Payload.Selection_Target =
             A11y.Node_Ids.No_Node
           and then Boundary_Reply.Payload.Selection_Request =
             A11y.Windows_Backend.UIA_Selection.Clear_Selection;

         Snapshots.all.Relation_Source := Root;
         A11y.Relations.Add
           (Snapshots.all.Relations,
            Root,
            A11y.Relations.Labelled_By,
            Selection_Item,
            Result);
         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Relation_Targets;
         Boundary_Request.Relation := A11y.Relations.Labelled_By;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Relation_Target_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Relation_Targets;
         Relation_Target_Payload_Preserved :=
           Relation_Target_Dispatched
           and then Boundary_Reply.Payload.Relation_Property =
             A11y.Windows_Backend.UIA_Mappings.Labeled_By;

         Snapshots.all.Document.Id := Root;
         Snapshots.all.Document.Root := Root;
         Snapshots.all.Document.Metadata.Role := A11y.Documents.Heading;
         Snapshots.all.Document.Metadata.Heading_Level := 2;
         Snapshots.all.Document.Metadata.Title :=
           To_Unbounded_String ("Probe Document");

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Document;
         Boundary_Request.Document :=
           A11y.Windows_Backend.UIA_Document.Title;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Document_Title_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Document_String;
         Document_Title_Payload_Preserved :=
           Document_Title_Dispatched
           and then To_String (Boundary_Reply.Payload.Text) = "Probe Document";

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Document;
         Boundary_Request.Document :=
           A11y.Windows_Backend.UIA_Document.Heading_Level;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Document_Heading_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Document_UInt32;
         Document_Heading_Payload_Preserved :=
           Document_Heading_Dispatched
           and then Boundary_Reply.Payload.UInt32 = 2;

         Snapshots.all.Image.Id := Root;
         Snapshots.all.Image.Root := Root;
         Snapshots.all.Image.Metadata.Kind := A11y.Images.Informative;
         Snapshots.all.Image.Metadata.Alternative_Text :=
           To_Unbounded_String ("Probe image alternative");
         Snapshots.all.Image.Metadata.Has_Intrinsic_Size := True;
         Snapshots.all.Image.Metadata.Intrinsic_Dimensions :=
           (Width => 640, Height => 480);

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Image;
         Boundary_Request.Image :=
           A11y.Windows_Backend.UIA_Image.Description;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Image_Description_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Image_String;
         Image_Description_Payload_Preserved :=
           Image_Description_Dispatched
           and then To_String (Boundary_Reply.Payload.Text) =
             "Probe image alternative";

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Image;
         Boundary_Request.Image :=
           A11y.Windows_Backend.UIA_Image.Intrinsic_Size;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Image_Size_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Image_Size;
         Image_Size_Payload_Preserved :=
           Image_Size_Dispatched
           and then Boundary_Reply.Payload.Size.Width = 640
           and then Boundary_Reply.Payload.Size.Height = 480;

         Snapshots.all.Live_Region.Id := Root;
         Snapshots.all.Live_Region.Metadata.Setting :=
           A11y.Live_Regions.Assertive;
         Snapshots.all.Live_Region.Metadata.Atomic := True;
         Snapshots.all.Live_Region.Metadata.Relevant :=
           A11y.Live_Regions.With_Change
             (A11y.Live_Regions.Empty_Relevant_Change_Set,
              A11y.Live_Regions.Text);

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Live_Region;
         Boundary_Request.Live_Region :=
           A11y.Windows_Backend.UIA_Live_Regions.Setting_Name;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Live_Setting_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Live_String;
         Live_Setting_Payload_Preserved :=
           Live_Setting_Dispatched
           and then To_String (Boundary_Reply.Payload.Text) = "assertive";

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Live_Region;
         Boundary_Request.Live_Region :=
           A11y.Windows_Backend.UIA_Live_Regions.Is_Atomic;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Live_Atomic_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Live_Boolean;
         Live_Atomic_Payload_Preserved :=
           Live_Atomic_Dispatched
           and then Boundary_Reply.Payload.Boolean_Item;

         Snapshots.all.Surface.Id := Root;
         Snapshots.all.Surface.Root := Root;
         Snapshots.all.Surface.Metadata.Kind := A11y.Windows.Dialog;
         A11y.Windows.Set_State
           (Snapshots.all.Surface.Metadata.State,
            A11y.Windows.Visible,
            True);
         A11y.Windows.Set_State
           (Snapshots.all.Surface.Metadata.State,
            A11y.Windows.Active,
            True);

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Surface;
         Boundary_Request.Surface :=
           A11y.Windows_Backend.UIA_Surfaces.Kind_Name;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Surface_Kind_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Surface_String;
         Surface_Kind_Payload_Preserved :=
           Surface_Kind_Dispatched
           and then To_String (Boundary_Reply.Payload.Text) = "dialog";

         Boundary_Request.Kind :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Get_Surface;
         Boundary_Request.Surface :=
           A11y.Windows_Backend.UIA_Surfaces.Is_Active;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
             (Boundary_Request, Snapshots.all);
         Surface_Active_Dispatched :=
           Boundary_Reply.Kind =
             A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
           and then Boundary_Reply.HResult =
             A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.Windows_Backend.UIA_Request_Router.Surface_Boolean;
         Surface_Active_Payload_Preserved :=
           Surface_Active_Dispatched
           and then Boundary_Reply.Payload.Boolean_Item;

         A11y.Native_Runtimes.Ensure_Object
           (Runtime, Root, Focus_Object, Result);
         if A11y.Results.Succeeded (Result) then
            A11y.Native_Focus_Calls.Query_Object_Focused
              (Focus_Gate,
               Runtime,
               Focus_Dispatcher,
               Focus_Object,
               Focus_Node,
               Focus_Query_Result);
            Native_Focus_Query_Dispatched :=
              Focus_Query_Result.Status = A11y.Results.Success;
            Native_Focus_Query_Payload_Preserved :=
              Native_Focus_Query_Dispatched
              and then Focus_Query_Result.Node = Root
              and then Focus_Query_Result.Focused
              and then Focus_Gate.Snapshot.Outstanding = 0;

            A11y.Native_Focus_Calls.Request_Object_Focus
              (Focus_Gate,
               Runtime,
               Focus_Dispatcher,
               Focus_Object,
               Focus_Action_Provider,
               Focus_Action_Result);
            Native_Set_Focus_Dispatched :=
              Focus_Action_Result.Status = A11y.Results.Success;
            Native_Set_Focus_Payload_Preserved :=
              Native_Set_Focus_Dispatched
              and then Focus_Action_Provider.Calls = 1
              and then Focus_Gate.Snapshot.Outstanding = 0;
         end if;

         A11y.Windows_Backend.UIA_Com_Providers.End_Native_Call
           (Provider,
            Context,
            End_Result);
         Provider_After_Call :=
           A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Provider);
         Native_Call_Completed :=
           A11y.Results.Succeeded (End_Result)
           and then not
             A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Context).Active
           and then Provider_After_Call.Active_Calls = 0
           and then Provider_After_Call.Call_Generation >
             Call_Snapshot.Native_Call_Generation;
         Native_Call_Drained :=
           Native_Call_Completed
           and then A11y.Windows_Backend.UIA_Com_Providers.Drained
             (Provider);
      end if;

      Ada.Text_IO.Put_Line ("{");
      Ada.Text_IO.Put_Line
        ("  ""schema"": "
         & Q ("org.a11y.native_client_uia_probe.v1")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""client_process"": "
         & Q (A11y_Native_Client_Reports.Client_Process_Name
                (A11y_Native_Client_Reports.Windows_UIA))
         & ",");
      Ada.Text_IO.Put_Line ("  ""platform"": ""Windows"",");
      Ada.Text_IO.Put_Line ("  ""native_api"": ""UI Automation"",");
      Ada.Text_IO.Put_Line
        ("  ""runtime_started"": "
         & (if Started then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""event_prepared"": "
         & (if Prepared_OK then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""envelope_valid"": "
         & (if Report.Envelope_Valid then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_object_resolved"": "
         & (if Report.Native_Object_Resolved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""publishable"": "
         & (if Report.Publishable then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_provider_created"": "
         & (if Native_Provider_Created then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_call_admitted"": "
         & (if Native_Call_Admitted then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_call_completed"": "
         & (if Native_Call_Completed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_call_drained"": "
         & (if Native_Call_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""host_window_bound"": "
         & (if Host_Window_Bound then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""host_window_component"": "
         & Trimmed (Natural'Image (Host_Window_Component))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""com_vtable_descriptor_built"": "
         & (if COM_VTable_Descriptor_Built then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""com_vtable_query_interface_planned"": "
         & (if COM_VTable_QueryInterface_Planned then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""com_vtable_frame_planned"": "
         & (if COM_VTable_Frame_Planned then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""com_object_token_exported"": "
         & (if COM_Object_Token_Exported then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""com_object_token_resolved"": "
         & (if COM_Object_Token_Resolved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""com_object_token_released"": "
         & (if COM_Object_Token_Released then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""com_object_token_not_reused"": "
         & (if COM_Object_Token_Not_Reused then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""com_live_interface_queried"": "
         & (if COM_Live_Interface_Queried then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""com_live_interface_retained"": "
         & (if COM_Live_Interface_Retained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""com_live_interface_released"": "
         & (if COM_Live_Interface_Released then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""com_live_released_interface_rejected"": "
         & (if COM_Live_Released_Interface_Rejected then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""com_live_interface_dispatched"": "
         & (if COM_Live_Interface_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""com_live_interface_frame_dispatched"": "
         & (if COM_Live_Interface_Frame_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""com_live_invalid_interface_frame_rejected"": "
         & (if COM_Live_Invalid_Interface_Frame_Rejected
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""com_live_invalid_method_frame_rejected"": "
         & (if COM_Live_Invalid_Method_Frame_Rejected
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""com_live_interface_method_mismatch_rejected"": "
         & (if COM_Live_Interface_Method_Mismatch_Rejected
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""com_live_fragment_navigate_dispatched"": "
         & (if COM_Live_Fragment_Navigate_Dispatched
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""com_live_fragment_runtime_id_dispatched"": "
         & (if COM_Live_Fragment_Runtime_Id_Dispatched
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""boundary_query_dispatched"": "
         & (if Boundary_Query_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""automation_id_dispatched"": "
         & (if Automation_Id_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""automation_id_payload_preserved"": "
         & (if Automation_Id_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""action_discovery_dispatched"": "
         & (if Action_Discovery_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""action_payload_preserved"": "
         & (if Action_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""action_request_dispatched"": "
         & (if Action_Request_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""action_request_payload_preserved"": "
         & (if Action_Request_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_range_dispatched"": "
         & (if Text_Range_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_range_payload_preserved"": "
         & (if Text_Range_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_edit_dispatched"": "
         & (if Text_Edit_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_edit_payload_preserved"": "
         & (if Text_Edit_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_delete_dispatched"": "
         & (if Text_Delete_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_delete_payload_preserved"": "
         & (if Text_Delete_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_replace_dispatched"": "
         & (if Text_Replace_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_replace_payload_preserved"": "
         & (if Text_Replace_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_set_dispatched"": "
         & (if Text_Set_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_set_payload_preserved"": "
         & (if Text_Set_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_current_cell_dispatched"": "
         & (if Table_Current_Cell_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_current_cell_payload_preserved"": "
         & (if Table_Current_Cell_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_sort_order_dispatched"": "
         & (if Table_Sort_Order_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_sort_order_payload_preserved"": "
         & (if Table_Sort_Order_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_sort_key_dispatched"": "
         & (if Table_Sort_Key_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_sort_key_payload_preserved"": "
         & (if Table_Sort_Key_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_current_dispatched"": "
         & (if Value_Current_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_current_payload_preserved"": "
         & (if Value_Current_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_set_dispatched"": "
         & (if Value_Set_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_set_payload_preserved"": "
         & (if Value_Set_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_count_dispatched"": "
         & (if Selection_Count_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_count_payload_preserved"": "
         & (if Selection_Count_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_item_dispatched"": "
         & (if Selection_Item_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_item_payload_preserved"": "
         & (if Selection_Item_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_request_dispatched"": "
         & (if Selection_Request_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_request_payload_preserved"": "
         & (if Selection_Request_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_select_all_dispatched"": "
         & (if Selection_Select_All_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_select_all_payload_preserved"": "
         & (if Selection_Select_All_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_clear_dispatched"": "
         & (if Selection_Clear_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_clear_payload_preserved"": "
         & (if Selection_Clear_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""relation_target_dispatched"": "
         & (if Relation_Target_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""relation_target_payload_preserved"": "
         & (if Relation_Target_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_title_dispatched"": "
         & (if Document_Title_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_title_payload_preserved"": "
         & (if Document_Title_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_heading_dispatched"": "
         & (if Document_Heading_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_heading_payload_preserved"": "
         & (if Document_Heading_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_description_dispatched"": "
         & (if Image_Description_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_description_payload_preserved"": "
         & (if Image_Description_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_size_dispatched"": "
         & (if Image_Size_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_size_payload_preserved"": "
         & (if Image_Size_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""live_setting_dispatched"": "
         & (if Live_Setting_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""live_setting_payload_preserved"": "
         & (if Live_Setting_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""live_atomic_dispatched"": "
         & (if Live_Atomic_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""live_atomic_payload_preserved"": "
         & (if Live_Atomic_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""surface_kind_dispatched"": "
         & (if Surface_Kind_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""surface_kind_payload_preserved"": "
         & (if Surface_Kind_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""surface_active_dispatched"": "
         & (if Surface_Active_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""surface_active_payload_preserved"": "
         & (if Surface_Active_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_focus_query_dispatched"": "
         & (if Native_Focus_Query_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_focus_query_payload_preserved"": "
         & (if Native_Focus_Query_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_set_focus_dispatched"": "
         & (if Native_Set_Focus_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_set_focus_payload_preserved"": "
         & (if Native_Set_Focus_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""missing_identity_rejected"": "
         & (if Missing_Identity_Rejected then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""mismatched_identity_rejected"": "
         & (if Mismatched_Identity_Rejected then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""malformed_identity_rejected"": "
         & (if Malformed_Identity_Rejected then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_payload_limit_rejected"": "
         & (if Text_Payload_Limit_Rejected then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""probe_status"": "
         & Q (if Probe_Completed then "success" else "incomplete")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""failure_stage"": " & Q (Failure_Stage) & ",");
      Ada.Text_IO.Put_Line
        ("  ""boundary_status"": " & Q (Status_Name (Boundary_Status)) & ",");
      Ada.Text_IO.Put_Line
        ("  ""status"": " & Q (Status_Name (Report.Status)));
      Ada.Text_IO.Put_Line ("}");
   exception
      when others =>
         Ada.Text_IO.Put_Line ("{");
         Ada.Text_IO.Put_Line
           ("  ""schema"": "
         & Q ("org.a11y.native_client_uia_probe.v1")
         & ",");
         Ada.Text_IO.Put_Line ("  ""client_process"": ""native_client_uia"",");
         Ada.Text_IO.Put_Line ("  ""platform"": ""Windows"",");
         Ada.Text_IO.Put_Line ("  ""native_api"": ""UI Automation"",");
         Ada.Text_IO.Put_Line ("  ""runtime_started"": false,");
         Ada.Text_IO.Put_Line ("  ""event_prepared"": false,");
         Ada.Text_IO.Put_Line ("  ""envelope_valid"": false,");
         Ada.Text_IO.Put_Line ("  ""native_object_resolved"": false,");
         Ada.Text_IO.Put_Line ("  ""publishable"": false,");
         Ada.Text_IO.Put_Line ("  ""native_provider_created"": false,");
         Ada.Text_IO.Put_Line ("  ""native_call_admitted"": false,");
         Ada.Text_IO.Put_Line ("  ""native_call_completed"": false,");
         Ada.Text_IO.Put_Line ("  ""native_call_drained"": false,");
         Ada.Text_IO.Put_Line ("  ""host_window_bound"": false,");
         Ada.Text_IO.Put_Line ("  ""host_window_component"": 0,");
         Ada.Text_IO.Put_Line ("  ""com_vtable_descriptor_built"": false,");
         Ada.Text_IO.Put_Line
           ("  ""com_vtable_query_interface_planned"": false,");
         Ada.Text_IO.Put_Line ("  ""com_vtable_frame_planned"": false,");
         Ada.Text_IO.Put_Line ("  ""com_object_token_exported"": false,");
         Ada.Text_IO.Put_Line ("  ""com_object_token_resolved"": false,");
         Ada.Text_IO.Put_Line ("  ""com_object_token_released"": false,");
         Ada.Text_IO.Put_Line ("  ""com_object_token_not_reused"": false,");
         Ada.Text_IO.Put_Line ("  ""com_live_interface_queried"": false,");
         Ada.Text_IO.Put_Line ("  ""com_live_interface_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""com_live_interface_frame_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""com_live_fragment_navigate_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""com_live_fragment_runtime_id_dispatched"": false,");
         Ada.Text_IO.Put_Line ("  ""boundary_query_dispatched"": false,");
         Ada.Text_IO.Put_Line ("  ""automation_id_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""automation_id_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""action_discovery_dispatched"": false,");
         Ada.Text_IO.Put_Line ("  ""action_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""action_request_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""action_request_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""text_range_dispatched"": false,");
         Ada.Text_IO.Put_Line ("  ""text_range_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""text_edit_dispatched"": false,");
         Ada.Text_IO.Put_Line ("  ""text_edit_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""text_delete_dispatched"": false,");
         Ada.Text_IO.Put_Line ("  ""text_delete_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""text_replace_dispatched"": false,");
         Ada.Text_IO.Put_Line ("  ""text_replace_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""text_set_dispatched"": false,");
         Ada.Text_IO.Put_Line ("  ""text_set_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""table_current_cell_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_current_cell_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""table_sort_order_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_sort_order_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""table_sort_key_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_sort_key_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""value_current_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_current_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""value_set_dispatched"": false,");
         Ada.Text_IO.Put_Line ("  ""value_set_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""selection_count_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_count_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""selection_item_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_item_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""selection_request_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_request_payload_preserved"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_select_all_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_select_all_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""selection_clear_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_clear_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""document_title_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""document_title_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""document_heading_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""document_heading_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""image_description_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_description_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""image_size_dispatched"": false,");
         Ada.Text_IO.Put_Line ("  ""image_size_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""live_setting_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""live_setting_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""live_atomic_dispatched"": false,");
         Ada.Text_IO.Put_Line ("  ""live_atomic_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""surface_kind_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""surface_kind_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""surface_active_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""surface_active_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""native_focus_query_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""native_focus_query_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""native_set_focus_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""native_set_focus_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""probe_status"": ""failed"",");
         Ada.Text_IO.Put_Line ("  ""failure_stage"": ""exception"",");
         Ada.Text_IO.Put_Line ("  ""boundary_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line ("  ""status"": ""INTERNAL_ERROR""");
         Ada.Text_IO.Put_Line ("}");
   end Emit_Runtime_Probe;

   procedure Emit_External_Client_Probe is
      Session : constant A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.Create_Session;
      Root : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (901);
      Child : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (902);
      type External_Provider_Registry_Access is access
        A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      type External_Object_Export_Table_Access is access
        A11y.Windows_Backend.UIA_COM_Object_Exports
          .COM_Object_Export_Table;
      Provider_Registry : constant External_Provider_Registry_Access := new
        A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Provider_Id :
        A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id :=
          A11y.Windows_Backend.UIA_Provider_Registry.No_Provider;
      Object_Export_Table : constant External_Object_Export_Table_Access :=
        new A11y.Windows_Backend.UIA_COM_Object_Exports
          .COM_Object_Export_Table;
      Object_Export :
        A11y.Windows_Backend.UIA_COM_Object_Exports.Object_Export_Report;
      Object_Release :
        A11y.Windows_Backend.UIA_COM_Object_Exports.Object_Release_Report;
      Public_Root_Export :
        A11y.Windows_Backend.UIA_Public_Roots.Public_Root_Export_Report;
      Released_Object_Resolve :
        A11y.Windows_Backend.UIA_COM_Object_Exports.Object_Resolve_Report;
      Fragment_Interface_Query :
        A11y.Windows_Backend.UIA_COM_Live_Exports.Interface_Query_Report;
      Fragment_Interface :
        A11y.Windows_Backend.UIA_COM_Live_Exports.UIA_Interface_Reference;
      Simple_Interface_Query :
        A11y.Windows_Backend.UIA_COM_Live_Exports.Interface_Query_Report;
      Simple_Interface :
        A11y.Windows_Backend.UIA_COM_Live_Exports.UIA_Interface_Reference;
      Root_Interface_Query :
        A11y.Windows_Backend.UIA_COM_Live_Exports.Interface_Query_Report;
      Root_Interface :
        A11y.Windows_Backend.UIA_COM_Live_Exports.UIA_Interface_Reference;
      type Interface_Dispatch_Report_Access is access
        A11y.Windows_Backend.UIA_COM_Live_Exports.Interface_Dispatch_Report;
      Navigate_Dispatch : constant Interface_Dispatch_Report_Access := new
        A11y.Windows_Backend.UIA_COM_Live_Exports.Interface_Dispatch_Report;
      Runtime_Id_Frame :
        A11y.Windows_Backend.UIA_COM_Live_Exports.ABI_Interface_Frame;
      Last_Child_Frame :
        A11y.Windows_Backend.UIA_COM_Live_Exports.ABI_Interface_Frame;
      Last_Child_Frame_Dispatch :
        A11y.Windows_Backend.UIA_COM_Live_Exports
          .ABI_Interface_Frame_Report;
      Runtime_Id_Frame_Dispatch :
        A11y.Windows_Backend.UIA_COM_Live_Exports
          .ABI_Interface_Frame_Report;
      Embedded_Fragment_Roots_Frame :
        A11y.Windows_Backend.UIA_COM_Live_Exports.ABI_Interface_Frame;
      Embedded_Fragment_Roots_Frame_Dispatch :
        A11y.Windows_Backend.UIA_COM_Live_Exports
          .ABI_Interface_Frame_Report;
      Fragment_Root_Frame :
        A11y.Windows_Backend.UIA_COM_Live_Exports.ABI_Interface_Frame;
      Fragment_Root_Frame_Dispatch :
        A11y.Windows_Backend.UIA_COM_Live_Exports
          .ABI_Interface_Frame_Report;
      Root_Point_Frame :
        A11y.Windows_Backend.UIA_COM_Live_Exports.ABI_Interface_Frame;
      Root_Point_Frame_Dispatch :
        A11y.Windows_Backend.UIA_COM_Live_Exports
          .ABI_Interface_Frame_Report;
      Root_Focus_Frame :
        A11y.Windows_Backend.UIA_COM_Live_Exports.ABI_Interface_Frame;
      Root_Focus_Frame_Dispatch :
        A11y.Windows_Backend.UIA_COM_Live_Exports
          .ABI_Interface_Frame_Report;
      Provider_Options_Frame :
        A11y.Windows_Backend.UIA_COM_Live_Exports.ABI_Interface_Frame;
      Provider_Options_Frame_Dispatch :
        A11y.Windows_Backend.UIA_COM_Live_Exports
          .ABI_Interface_Frame_Report;
      Host_Raw_Element_Provider_Frame :
        A11y.Windows_Backend.UIA_COM_Live_Exports.ABI_Interface_Frame;
      Host_Raw_Element_Provider_Frame_Dispatch :
        A11y.Windows_Backend.UIA_COM_Live_Exports
          .ABI_Interface_Frame_Report;
      Pattern_Provider_Frame :
        A11y.Windows_Backend.UIA_COM_Live_Exports.ABI_Interface_Frame;
      Pattern_Provider_Frame_Dispatch :
        A11y.Windows_Backend.UIA_COM_Live_Exports
          .ABI_Interface_Frame_Report;
      Bounding_Rectangle_Frame :
        A11y.Windows_Backend.UIA_COM_Live_Exports.ABI_Interface_Frame;
      Bounding_Rectangle_Frame_Dispatch :
        A11y.Windows_Backend.UIA_COM_Live_Exports
          .ABI_Interface_Frame_Report;
      Property_Frame :
        A11y.Windows_Backend.UIA_COM_Live_Exports.ABI_Interface_Frame;
      Property_Frame_Dispatch :
        A11y.Windows_Backend.UIA_COM_Live_Exports
          .ABI_Interface_Frame_Report;
      Action_Frame :
        A11y.Windows_Backend.UIA_COM_Live_Exports.ABI_Interface_Frame;
      Action_Frame_Dispatch :
        A11y.Windows_Backend.UIA_COM_Live_Exports
          .ABI_Interface_Frame_Report;
      Release_Report :
        A11y.Windows_Backend.UIA_COM_Live_Exports.Interface_Lifetime_Report;
      Released_Dispatch :
        A11y.Windows_Backend.UIA_COM_Live_Exports.Interface_Dispatch_Report;
      type Snapshot_Access is access
        A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Snapshots : constant Snapshot_Access := new
        A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Reply : A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply;
      Result : A11y.Results.Result;
      Provider_Export_Observed : Boolean := False;
      Fragment_Interface_Queried : Boolean := False;
      Fragment_Navigate_Dispatched : Boolean := False;
      Fragment_Last_Child_Frame_Dispatched : Boolean := False;
      Fragment_Runtime_Id_Dispatched : Boolean := False;
      Embedded_Fragment_Roots_Dispatched : Boolean := False;
      Fragment_Root_Dispatched : Boolean := False;
      Root_Interface_Queried : Boolean := False;
      Root_Point_Dispatched : Boolean := False;
      Root_Focus_Dispatched : Boolean := False;
      Provider_Options_Dispatched : Boolean := False;
      Host_Raw_Element_Provider_Dispatched : Boolean := False;
      Pattern_Provider_Frame_Dispatched : Boolean := False;
      Bounding_Rectangle_Frame_Dispatched : Boolean := False;
      Simple_Property_Frame_Dispatched : Boolean := False;
      Fragment_Action_Frame_Dispatched : Boolean := False;
      Fragment_Set_Focus_Payload_Preserved : Boolean := False;
      Fragment_Action_Frame_Status : A11y.Results.Status_Code :=
        A11y.Results.Internal_Error;
      Fragment_Action_Frame_Routed :
        A11y.Windows_Backend.UIA_Request_Router.Routed_Reply_Kind :=
          A11y.Windows_Backend.UIA_Request_Router.Routed_Error;
      Fragment_Navigate_Reply_Status : A11y.Results.Status_Code :=
        A11y.Results.Internal_Error;
      Fragment_Navigate_Reply_Routed :
        A11y.Windows_Backend.UIA_Request_Router.Routed_Reply_Kind :=
          A11y.Windows_Backend.UIA_Request_Router.Routed_Error;
      Fragment_Root_Reply_Status : A11y.Results.Status_Code :=
        A11y.Results.Internal_Error;
      Fragment_Root_Reply_Routed :
        A11y.Windows_Backend.UIA_Request_Router.Routed_Reply_Kind :=
          A11y.Windows_Backend.UIA_Request_Router.Routed_Error;
      Fragment_Root_Reply_Node : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Bounding_Rectangle_Reply_Status : A11y.Results.Status_Code :=
        A11y.Results.Internal_Error;
      Bounding_Rectangle_Reply_Routed :
        A11y.Windows_Backend.UIA_Request_Router.Routed_Reply_Kind :=
          A11y.Windows_Backend.UIA_Request_Router.Routed_Error;
      Bounding_Rectangle_Matches : Boolean := False;
      Released_Interface_Rejected : Boolean := False;
      Object_Token_Released : Boolean := False;
      Released_Object_Token_Rejected : Boolean := False;
      Metadata_Name_Preserved : Boolean := False;
      Metadata_Identifier_Preserved : Boolean := False;
      Metadata_Help_Preserved : Boolean := False;
      Metadata_Placeholder_Preserved : Boolean := False;
      Metadata_Detail_Preserved : Boolean := False;
      Protected_Value_Suppressed : Boolean := False;
      Semantic_State_Mutated : constant Boolean := False;
      Boundary_Status : A11y.Results.Status_Code := A11y.Results.Success;
      Client_Runtime_Probe :
        aliased A11y.Windows_Backend.UIA_Native_Bridge
          .Client_Runtime_Probe;
      Client_Runtime_Return :
        A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 := 0;
      Client_Runtime_Probed : Boolean := False;
      Client_Runtime_Available : Boolean := False;
      Host_Window_Probe :
        aliased A11y.Windows_Backend.UIA_Native_Bridge
          .Host_Window_Probe;
      Host_Window_Return :
        A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 := 0;
      Host_Window_Probed : Boolean := False;
      Host_Window_Handshake_Available : Boolean := False;
      Minimal_Provider_Probe :
        aliased A11y.Windows_Backend.UIA_Native_Bridge
          .Minimal_Provider_Host_Window_Probe;
      Minimal_Provider_Return :
        A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 := 0;
      Minimal_Provider_Probed : Boolean := False;
      Minimal_Provider_Host_Window_Available : Boolean := False;
      Callback_Provider_Probe :
        aliased A11y.Windows_Backend.UIA_Native_Bridge
          .Callback_Provider_Host_Window_Probe;
      Callback_Provider_Return :
        A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 := 0;
      Callback_Provider_Probed : Boolean := False;
      Callback_Provider_Host_Window_Available : Boolean := False;
      Callback_Context :
        aliased A11y.Windows_Backend.UIA_Native_Callbacks.Callback_Context;
      Callback_Provider_Session :
        A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt64 := 0;
      Callback_Provider_Id :
        A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt64 := 0;
      Callback_Provider_Object_Token :
        A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt64 := 0;
      Callback_Provider_Options_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Simple_Get_Provider_Options));
      Callback_Provider_Pattern_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Simple_Get_Pattern_Provider));
      Callback_Provider_Property_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Simple_Get_Property_Value));
      Callback_Provider_Host_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Simple_Get_Host_Raw_Element_Provider));
      Callback_Fragment_Navigate_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface.Fragment_Navigate));
      Callback_Fragment_Runtime_Id_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Fragment_Get_Runtime_Id));
      Callback_Fragment_Bounding_Rectangle_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Fragment_Get_Bounding_Rectangle));
      Callback_Fragment_Embedded_Roots_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Fragment_Get_Embedded_Fragment_Roots));
      Callback_Fragment_Set_Focus_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface.Fragment_Set_Focus));
      Callback_Fragment_Root_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Fragment_Get_Fragment_Root));
      Callback_Root_From_Point_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Fragment_Root_Element_Provider_From_Point));
      Callback_Root_Get_Focus_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Fragment_Root_Get_Focus));
      Callback_Invoke_Provider_Invoke_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Invoke_Provider_Invoke));
      Callback_Toggle_Provider_Toggle_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Toggle_Provider_Toggle));
      Callback_Expand_Collapse_Provider_Expand_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Expand_Collapse_Provider_Expand));
      Callback_Expand_Collapse_Provider_Collapse_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Expand_Collapse_Provider_Collapse));
      Callback_Scroll_Item_Provider_Scroll_Into_View_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Scroll_Item_Provider_Scroll_Into_View));
      Callback_Selection_Item_Provider_Select_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Selection_Item_Provider_Select));
      Callback_Selection_Item_Provider_Add_To_Selection_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Selection_Item_Provider_Add_To_Selection));
      Callback_Selection_Item_Provider_Remove_From_Selection_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Selection_Item_Provider_Remove_From_Selection));
      Callback_Selection_Item_Provider_Get_Is_Selected_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Selection_Item_Provider_Get_Is_Selected));
      Callback_Selection_Item_Provider_Get_Selection_Container_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Selection_Item_Provider_Get_Selection_Container));
      Callback_Range_Value_Provider_Set_Value_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Range_Value_Provider_Set_Value));
      Callback_Range_Value_Provider_Get_Value_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Range_Value_Provider_Get_Value));
      Callback_Range_Value_Provider_Get_Is_Read_Only_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Range_Value_Provider_Get_Is_Read_Only));
      Callback_Range_Value_Provider_Get_Maximum_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Range_Value_Provider_Get_Maximum));
      Callback_Range_Value_Provider_Get_Minimum_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Range_Value_Provider_Get_Minimum));
      Callback_Range_Value_Provider_Get_Large_Change_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Range_Value_Provider_Get_Large_Change));
      Callback_Range_Value_Provider_Get_Small_Change_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Range_Value_Provider_Get_Small_Change));
      Callback_Window_Provider_Close_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface.Window_Provider_Close));
      Callback_Window_Provider_Get_Can_Maximize_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Window_Provider_Get_Can_Maximize));
      Callback_Window_Provider_Get_Can_Minimize_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Window_Provider_Get_Can_Minimize));
      Callback_Window_Provider_Get_Is_Modal_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Window_Provider_Get_Is_Modal));
      Callback_Window_Provider_Get_Visual_State_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Window_Provider_Get_Window_Visual_State));
      Callback_Window_Provider_Get_Interaction_State_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Window_Provider_Get_Window_Interaction_State));
      Callback_Advise_Events_Advise_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Advise_Events_Advise));
      Callback_Advise_Events_Unadvise_Method :
        constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 :=
          A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
            (A11y.Windows_Backend.UIA_ABI_Surface.Method_Code
               (A11y.Windows_Backend.UIA_ABI_Surface
                  .Advise_Events_Unadvise));
      Bridge_Target_Is_Windows : constant Boolean :=
        A11y.Windows_Backend.UIA_Native_Bridge.Bridge_Is_Windows /= 0;

      function String_Property_Matches
        (Property : A11y.Windows_Backend.UIA_Properties.Core_Property;
         Expected : String)
         return Boolean
      is
         Property_Reply : constant
           A11y.Windows_Backend.UIA_Properties.Property_Reply :=
             A11y.Windows_Backend.UIA_Properties.Query_Property
               (Snapshots.all.Properties, Property);
      begin
         return Property_Reply.Kind =
             A11y.Windows_Backend.UIA_Properties.String_Reply
           and then Property_Reply.Status = A11y.Results.Success
           and then To_String (Property_Reply.Text) = Expected;
      end String_Property_Matches;

      function Property_Permission_Denied
        (Property : A11y.Windows_Backend.UIA_Properties.Core_Property)
         return Boolean
      is
         Property_Reply : constant
           A11y.Windows_Backend.UIA_Properties.Property_Reply :=
             A11y.Windows_Backend.UIA_Properties.Query_Property
               (Snapshots.all.Properties, Property);
      begin
         return Property_Reply.Kind =
             A11y.Windows_Backend.UIA_Properties.Error_Reply
           and then Property_Reply.Status = A11y.Results.Permission_Denied;
      end Property_Permission_Denied;

      function Failure_Stage return String is
      begin
         if not Provider_Export_Observed then
            return "com_provider_export";
         elsif not Fragment_Interface_Queried then
            return "fragment_interface_query";
         elsif not Fragment_Navigate_Dispatched then
            return "fragment_navigation";
         elsif not Fragment_Last_Child_Frame_Dispatched then
            return "fragment_last_child_frame";
         elsif not Fragment_Runtime_Id_Dispatched then
            return "runtime_identifier";
         elsif not Embedded_Fragment_Roots_Dispatched then
            return "embedded_fragment_roots";
         elsif not Fragment_Root_Dispatched then
            return "fragment_root";
         elsif not Root_Interface_Queried then
            return "fragment_root_interface_query";
         elsif not Root_Point_Dispatched then
            return "fragment_root_point";
         elsif not Root_Focus_Dispatched then
            return "fragment_root_focus";
         elsif not Provider_Options_Dispatched then
            return "provider_options";
         elsif not Host_Raw_Element_Provider_Dispatched then
            return "host_raw_element_provider";
         elsif not Pattern_Provider_Frame_Dispatched then
            return "pattern_provider_frame";
         elsif not Bounding_Rectangle_Frame_Dispatched then
            return "bounding_rectangle_frame";
         elsif not Simple_Property_Frame_Dispatched then
            return "simple_property_frame";
         elsif not Fragment_Action_Frame_Dispatched then
            return "fragment_action_frame";
         elsif not Fragment_Set_Focus_Payload_Preserved then
            return "fragment_set_focus_payload";
         elsif not Released_Interface_Rejected then
            return "stale_interface_rejection";
         elsif not Object_Token_Released then
            return "com_object_token_release";
         elsif not Released_Object_Token_Rejected then
            return "stale_object_token_rejection";
         else
            return "external_uia_client";
         end if;
      end Failure_Stage;

      function COM_Live_Chain_Observed return Boolean is
      begin
         return
           Provider_Export_Observed
           and then Fragment_Interface_Queried
           and then Fragment_Navigate_Dispatched
           and then Fragment_Last_Child_Frame_Dispatched
           and then Fragment_Runtime_Id_Dispatched
           and then Embedded_Fragment_Roots_Dispatched
           and then Fragment_Root_Dispatched
           and then Root_Interface_Queried
           and then Root_Point_Dispatched
           and then Root_Focus_Dispatched
           and then Provider_Options_Dispatched
           and then Host_Raw_Element_Provider_Dispatched
           and then Pattern_Provider_Frame_Dispatched
           and then Bounding_Rectangle_Frame_Dispatched
           and then Simple_Property_Frame_Dispatched
           and then Fragment_Action_Frame_Dispatched
           and then Fragment_Set_Focus_Payload_Preserved
           and then Released_Interface_Rejected
           and then Object_Token_Released
           and then Released_Object_Token_Rejected;
      end COM_Live_Chain_Observed;

      function Metadata_Group_Preserved return Boolean is
      begin
         return
           Metadata_Name_Preserved
           and then Metadata_Identifier_Preserved
           and then Metadata_Help_Preserved
           and then Metadata_Placeholder_Preserved
           and then Metadata_Detail_Preserved;
      end Metadata_Group_Preserved;

      function Privacy_Boundary_Observed return Boolean is
      begin
         return Protected_Value_Suppressed and then not Semantic_State_Mutated;
      end Privacy_Boundary_Observed;

      function Internal_Native_Export_Chain_Ready return Boolean is
      begin
         return
           COM_Live_Chain_Observed
           and then Metadata_Group_Preserved
           and then Privacy_Boundary_Observed;
      end Internal_Native_Export_Chain_Ready;

      function External_Client_Traversal_Observed return Boolean is
      begin
         return
           Client_Runtime_Available
           and then Minimal_Provider_Probed
           and then Minimal_Provider_Probe.Element_From_Handle_Succeeded /= 0
           and then Callback_Provider_Probed
           and then Callback_Provider_Probe.Return_Raw_Element_Provider_Nonzero
             /= 0
           and then Callback_Provider_Probe.Provider_Query_Interface_Called /= 0
           and then Callback_Provider_Probe
             .Pattern_Provider_Support_Callback_Succeeded /= 0
           and then Callback_Provider_Probe.Fragment_Navigate_Callback_Succeeded
             /= 0
           and then Callback_Provider_Probe.Fragment_Runtime_Id_Callback_Succeeded
             /= 0
           and then Callback_Provider_Probe.Fragment_Root_Callback_Succeeded /= 0
           and then Callback_Provider_Probe.Root_From_Point_Callback_Succeeded
             /= 0
           and then Callback_Provider_Probe.Root_Get_Focus_Callback_Succeeded
             /= 0
           and then Callback_Provider_Probe
             .Expand_Collapse_Provider_Expand_Callback_Succeeded /= 0
           and then Callback_Provider_Probe
             .Expand_Collapse_Provider_Collapse_Callback_Succeeded /= 0
           and then Callback_Provider_Probe
             .Toggle_Provider_Get_State_Callback_Succeeded /= 0
           and then Callback_Provider_Probe
             .Expand_Collapse_Provider_Get_State_Callback_Succeeded /= 0
           and then Callback_Provider_Probe
             .Scroll_Item_Provider_Scroll_Into_View_Callback_Succeeded /= 0
           and then Callback_Provider_Probe
             .Selection_Item_Provider_Select_Callback_Succeeded /= 0
           and then Callback_Provider_Probe
             .Selection_Item_Provider_Add_To_Selection_Callback_Succeeded /= 0
           and then Callback_Provider_Probe
             .Selection_Item_Provider_Remove_From_Selection_Callback_Succeeded
               /= 0
           and then Callback_Provider_Probe
             .Selection_Item_Provider_Get_Is_Selected_Callback_Succeeded /= 0
           and then Callback_Provider_Probe
             .Pattern_Provider_Returned_Range_Value /= 0
           and then Callback_Provider_Probe
             .Range_Value_Provider_Set_Value_Callback_Succeeded /= 0
           and then Callback_Provider_Probe
             .Range_Value_Provider_Get_Value_Callback_Succeeded /= 0
           and then Callback_Provider_Probe
             .Range_Value_Provider_Get_Is_Read_Only_Callback_Succeeded /= 0
           and then Callback_Provider_Probe
             .Range_Value_Provider_Get_Maximum_Callback_Succeeded /= 0
           and then Callback_Provider_Probe
             .Range_Value_Provider_Get_Minimum_Callback_Succeeded /= 0
           and then Callback_Provider_Probe
             .Range_Value_Provider_Get_Large_Change_Callback_Succeeded /= 0
           and then Callback_Provider_Probe
             .Range_Value_Provider_Get_Small_Change_Callback_Succeeded /= 0
           and then Callback_Provider_Probe
             .Window_Provider_Close_Callback_Succeeded /= 0
           and then Callback_Provider_Probe
             .Window_Provider_Get_Can_Maximize_Callback_Succeeded /= 0
           and then Callback_Provider_Probe
             .Window_Provider_Get_Can_Minimize_Callback_Succeeded /= 0
           and then Callback_Provider_Probe
             .Window_Provider_Get_Is_Modal_Callback_Succeeded /= 0
           and then Callback_Provider_Probe
             .Window_Provider_Get_Visual_State_Callback_Succeeded /= 0
           and then Callback_Provider_Probe
             .Window_Provider_Get_Interaction_State_Callback_Succeeded /= 0
           and then Callback_Provider_Probe
             .Advise_Events_Advise_Callback_Succeeded /= 0
           and then Callback_Provider_Probe
             .Advise_Events_Unadvise_Callback_Succeeded /= 0
           and then Callback_Provider_Probe.Full_Frame_Callback_Succeeded /= 0
           and then Internal_Native_Export_Chain_Ready
           and then Boundary_Status = A11y.Results.Success;
      end External_Client_Traversal_Observed;
   begin
      Client_Runtime_Return :=
        A11y.Windows_Backend.UIA_Native_Bridge.Probe_Client_Runtime
          (Client_Runtime_Probe'Access);
      Client_Runtime_Probed := True;
      Client_Runtime_Available :=
        Client_Runtime_Return /= 0
        and then Client_Runtime_Probe.Client_Runtime_Available /= 0;
      Host_Window_Return :=
        A11y.Windows_Backend.UIA_Native_Bridge.Probe_Host_Window_Handshake
          (Host_Window_Probe'Access);
      Host_Window_Probed := True;
      Host_Window_Handshake_Available :=
        Host_Window_Return /= 0;
      Minimal_Provider_Return :=
        A11y.Windows_Backend.UIA_Native_Bridge
          .Probe_Minimal_Provider_Host_Window
            (Minimal_Provider_Probe'Access);
      Minimal_Provider_Probed := True;
      Minimal_Provider_Host_Window_Available :=
        Minimal_Provider_Return /= 0;
      A11y.Trees.Set_Root (Snapshots.all.Fragment.Tree, Root, Result);
      if A11y.Results.Succeeded (Result) then
         A11y.Trees.Attach
           (Snapshots.all.Fragment.Tree, Root, Child, Result);
      end if;

      if not A11y.Results.Succeeded (Result) then
         Boundary_Status := Result.Status;
      else
         Snapshots.all.Properties.Id := Root;
         Snapshots.all.Properties.Root := Root;
         Snapshots.all.Properties.Role := A11y.Roles.Application;
         Snapshots.all.Properties.Name :=
           A11y.Properties.Present ("External UIA Probe");
         Snapshots.all.Properties.Automation_Id :=
           A11y.Properties.Present ("external-uia-probe");
         Snapshots.all.Properties.Help_Text :=
           A11y.Properties.Present ("External UIA help");
         Snapshots.all.Properties.Placeholder :=
           A11y.Properties.Present ("External UIA placeholder");
         Snapshots.all.Properties.Value_Text :=
           A11y.Properties.Present ("external-uia-secret");
         Snapshots.all.Properties.Protected_Value_Text := True;
         Snapshots.all.Properties.Visible_Title :=
           A11y.Properties.Present ("External UIA title");
         Snapshots.all.Properties.Keyboard_Shortcut :=
           A11y.Properties.Present ("Ctrl+Alt+U");
         Snapshots.all.Properties.Locale :=
           A11y.Properties.Present ("en-US");
         Snapshots.all.Properties.Orientation :=
           A11y.Properties.Present ("vertical");
         Snapshots.all.Properties.Landmark :=
           A11y.Properties.Present ("main");
         Snapshots.all.Properties.Defunct := False;
         Snapshots.all.Properties.Bounds :=
           (Origin => (X => -64, Y => 48),
            Extent => (Width => 320, Height => 72));
         Snapshots.all.Properties.States :=
           A11y.States.With_State
             (A11y.States.With_State
                (A11y.States.Empty_State_Set, A11y.States.Checked),
              A11y.States.Expanded);
         Snapshots.all.Properties.Exposure :=
           [others => A11y.Nodes.Expose_Node];
         Snapshots.all.Fragment.Session := Session;
         Snapshots.all.Fragment.Fragment_Root := Root;
         Snapshots.all.Fragment.Node := Root;
         Snapshots.all.Fragment.Focused_Node := Child;
         Snapshots.all.Fragment.Hit_Test_Point := (X => 2_000, Y => 2_000);
         Snapshots.all.Fragment.Bounds (A11y.Node_Ids.To_Natural (Root)) :=
           (Origin => (X => 10, Y => 20),
            Extent => (Width => 300, Height => 200));
         Snapshots.all.Fragment.Bounds (A11y.Node_Ids.To_Natural (Child)) :=
           (Origin => (X => 20, Y => 30),
            Extent => (Width => 40, Height => 40));
         Snapshots.all.Actions (A11y.Actions.Activate) := True;
         Snapshots.all.Actions (A11y.Actions.Toggle) := True;
         Snapshots.all.Actions (A11y.Actions.Expand) := True;
         Snapshots.all.Actions (A11y.Actions.Collapse) := True;
         Snapshots.all.Actions (A11y.Actions.Scroll_Into_View) := True;
        Snapshots.all.Actions (A11y.Actions.Select_Item) := True;
        Snapshots.all.Actions (A11y.Actions.Deselect) := True;
        Snapshots.all.Actions (A11y.Actions.Set_Focus) := True;
        Snapshots.all.Actions (A11y.Actions.Close) := True;
         Snapshots.all.Selection.Root := Root;
         Snapshots.all.Selection.Item := Root;
         Snapshots.all.Selection.Items.Append (Root);
         A11y.Selection.Configure
           (Snapshots.all.Selection.Selection, A11y.Selection.Multiple);
         A11y.Selection.Select_Item
           (Snapshots.all.Selection.Selection, Root, Result);
         if A11y.Results.Succeeded (Result) then
            A11y.Selection.Set_Current_Item
              (Snapshots.all.Selection.Selection, Root, Result);
         end if;
         Snapshots.all.Action_Node := Root;
         Snapshots.all.Action_Root := Root;

         Metadata_Name_Preserved :=
           String_Property_Matches
             (A11y.Windows_Backend.UIA_Properties.Name,
              "External UIA Probe");
         Metadata_Identifier_Preserved :=
           String_Property_Matches
             (A11y.Windows_Backend.UIA_Properties.Automation_Id,
              "external-uia-probe");
         Metadata_Help_Preserved :=
           String_Property_Matches
             (A11y.Windows_Backend.UIA_Properties.Help_Text,
              "External UIA help");
         Metadata_Placeholder_Preserved :=
           String_Property_Matches
             (A11y.Windows_Backend.UIA_Properties.Placeholder,
              "External UIA placeholder");
         Metadata_Detail_Preserved :=
           String_Property_Matches
             (A11y.Windows_Backend.UIA_Properties.Visible_Title,
              "External UIA title")
           and then String_Property_Matches
             (A11y.Windows_Backend.UIA_Properties.Keyboard_Shortcut,
              "Ctrl+Alt+U")
           and then String_Property_Matches
             (A11y.Windows_Backend.UIA_Properties.Locale, "en-US")
           and then String_Property_Matches
             (A11y.Windows_Backend.UIA_Properties.Orientation, "vertical")
           and then String_Property_Matches
             (A11y.Windows_Backend.UIA_Properties.Landmark, "main");
         Protected_Value_Suppressed :=
           Property_Permission_Denied
             (A11y.Windows_Backend.UIA_Properties.Value_Text);

         A11y.Windows_Backend.UIA_Public_Roots.Export_Public_Root
           (Provider_Registry.all,
            Object_Export_Table.all,
            Session,
            Root,
            Root,
            Public_Root_Export);

         if Public_Root_Export.Status /= A11y.Results.Success then
            Boundary_Status := Public_Root_Export.Status;
         else
            Provider_Id := Public_Root_Export.Provider;
            Object_Export := Public_Root_Export.Object_Export;
            Provider_Export_Observed :=
              Public_Root_Export.Provider_Ensured
              and then Public_Root_Export.Provider_Initialized
              and then Public_Root_Export.Export_Table_Built
              and then Public_Root_Export.Object_Descriptor_Built
              and then Public_Root_Export.Object_Exported
              and then Public_Root_Export.Fragment_Interface_Queryable
              and then Public_Root_Export.Simple_Interface_Queryable
              and then
                Public_Root_Export.Fragment_Root_Interface_Queryable;

            if Provider_Export_Observed then
               Callback_Context.Object_Table :=
                 Object_Export_Table.all'Unchecked_Access;
               Callback_Context.Registry :=
                 Provider_Registry.all'Unchecked_Access;
               Callback_Context.Snapshots :=
                 Snapshots.all'Unchecked_Access;
               Callback_Provider_Session :=
                 A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt64
                   (A11y.Native_Identity.To_Natural (Session));
               Callback_Provider_Id :=
                 A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt64
                   (A11y.Windows_Backend.UIA_Provider_Registry.To_Natural
                      (Provider_Id));
               Callback_Provider_Object_Token :=
                 A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt64
                   (A11y.Windows_Backend.UIA_COM_Object_Exports.To_Natural
                      (Object_Export.Token));
               Callback_Provider_Return :=
                 A11y.Windows_Backend.UIA_Native_Bridge
                   .Probe_Callback_Provider_Host_Window
                     (Callback_Provider_Session,
                      Callback_Provider_Id,
                      Callback_Provider_Object_Token,
                      Callback_Provider_Options_Method,
                      Callback_Provider_Pattern_Method,
                      Callback_Provider_Property_Method,
                      Callback_Provider_Host_Method,
                      Callback_Fragment_Navigate_Method,
                      Callback_Fragment_Runtime_Id_Method,
                      Callback_Fragment_Bounding_Rectangle_Method,
                      Callback_Fragment_Embedded_Roots_Method,
                      Callback_Fragment_Set_Focus_Method,
                      Callback_Fragment_Root_Method,
                      Callback_Root_From_Point_Method,
                      Callback_Root_Get_Focus_Method,
                      Callback_Invoke_Provider_Invoke_Method,
                      Callback_Toggle_Provider_Toggle_Method,
                      Callback_Expand_Collapse_Provider_Expand_Method,
                      Callback_Expand_Collapse_Provider_Collapse_Method,
                      Callback_Scroll_Item_Provider_Scroll_Into_View_Method,
                      Callback_Selection_Item_Provider_Select_Method,
                      Callback_Selection_Item_Provider_Add_To_Selection_Method,
                      Callback_Selection_Item_Provider_Remove_From_Selection_Method,
                      Callback_Selection_Item_Provider_Get_Is_Selected_Method,
                      Callback_Selection_Item_Provider_Get_Selection_Container_Method,
                      Callback_Range_Value_Provider_Set_Value_Method,
                      Callback_Range_Value_Provider_Get_Value_Method,
                      Callback_Range_Value_Provider_Get_Is_Read_Only_Method,
                      Callback_Range_Value_Provider_Get_Maximum_Method,
                      Callback_Range_Value_Provider_Get_Minimum_Method,
                      Callback_Range_Value_Provider_Get_Large_Change_Method,
                      Callback_Range_Value_Provider_Get_Small_Change_Method,
                      Callback_Window_Provider_Close_Method,
                      Callback_Window_Provider_Get_Can_Maximize_Method,
                      Callback_Window_Provider_Get_Can_Minimize_Method,
                      Callback_Window_Provider_Get_Is_Modal_Method,
                      Callback_Window_Provider_Get_Visual_State_Method,
                      Callback_Window_Provider_Get_Interaction_State_Method,
                      Callback_Advise_Events_Advise_Method,
                      Callback_Advise_Events_Unadvise_Method,
                      A11y_UIA_Native_Probe_Callbacks.Return_S_OK'Access,
                      A11y.Windows_Backend.UIA_Native_Callbacks
                        .Dispatch_Interface_Frame_Callback'Access,
                      A11y.Windows_Backend.UIA_Native_Callbacks
                        .Copy_Property_Value_Callback'Access,
                      A11y.Windows_Backend.UIA_Native_Callbacks
                        .Copy_Runtime_Id_Callback'Access,
                      A11y.Windows_Backend.UIA_Native_Callbacks
                        .Copy_Bounding_Rectangle_Callback'Access,
                      A11y.Windows_Backend.UIA_Native_Callbacks
                        .Copy_Boolean_Callback'Access,
                      A11y.Windows_Backend.UIA_Native_Callbacks
                        .Check_Pattern_Supported_Callback'Access,
                      A11y.Windows_Backend.UIA_Native_Callbacks
                        .Copy_Pattern_State_Callback'Access,
                      A11y.Windows_Backend.UIA_Native_Callbacks
                        .Dispatch_Range_Value_Set_Callback'Access,
                      A11y.Windows_Backend.UIA_Native_Callbacks
                        .Copy_Range_Value_Query_Callback'Access,
                      A11y.Windows_Backend.UIA_Native_Callbacks
                        .Copy_Window_Query_Callback'Access,
                      Callback_Context'Address,
                      Callback_Provider_Probe'Access);
               Callback_Provider_Probed := True;
               Callback_Provider_Host_Window_Available :=
                 Callback_Provider_Return /= 0;
            end if;

            Fragment_Interface_Query := Public_Root_Export.Fragment_Query;
            Fragment_Interface := Fragment_Interface_Query.Reference;
            Fragment_Interface_Queried :=
              Provider_Export_Observed
              and then Fragment_Interface_Query.Object_Resolved
              and then Fragment_Interface_Query.Query.Supported
              and then Fragment_Interface.Present;
            Reply :=
              A11y.Windows_Backend.UIA_COM_Live_Exports
                .Dispatch_Interface_Method_Access
                  (Object_Export_Table.all,
                   Fragment_Interface,
                   A11y.Windows_Backend.UIA_ABI_Surface.Fragment_Navigate,
                   Provider_Registry.all,
                   Snapshots,
                   Navigate_Dispatch.all,
                   A11y.Windows_Backend.UIA_Fragments.First_Child);
            Fragment_Navigate_Reply_Status := Reply.Status;
            Fragment_Navigate_Reply_Routed := Reply.Routed;
            Fragment_Navigate_Dispatched :=
              Fragment_Interface_Queried
              and then Reply.Kind =
                A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
              and then Reply.HResult =
                A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
              and then Reply.Routed =
                A11y.Windows_Backend.UIA_Request_Router.Fragment_Node
              and then Reply.Payload.Node = Child
              and then Navigate_Dispatch.all.Callback.Invoke
                .Registered_Dispatched;

            Last_Child_Frame :=
              A11y.Windows_Backend.UIA_COM_Live_Exports.Build_Interface_Frame
                (Fragment_Interface,
                 A11y.Windows_Backend.UIA_ABI_Surface.Fragment_Navigate,
                 A11y.Windows_Backend.UIA_Fragments.Last_Child);
            Reply :=
              A11y.Windows_Backend.UIA_COM_Live_Exports
                .Dispatch_Interface_Frame_Access
                  (Object_Export_Table.all,
                   Last_Child_Frame,
                   Provider_Registry.all,
                   Snapshots,
                   Last_Child_Frame_Dispatch);
            Fragment_Last_Child_Frame_Dispatched :=
              Fragment_Navigate_Dispatched
              and then Reply.Kind =
                A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
              and then Reply.HResult =
                A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
              and then Reply.Routed =
                A11y.Windows_Backend.UIA_Request_Router.Fragment_Node
              and then Reply.Payload.Node = Child
              and then Last_Child_Frame_Dispatch.Session_Code_Valid
              and then Last_Child_Frame_Dispatch.Provider_Code_Valid
              and then Last_Child_Frame_Dispatch.Object_Token_Valid
              and then Last_Child_Frame_Dispatch.Interface_Code_Valid
              and then Last_Child_Frame_Dispatch.Method_Code_Valid
              and then Last_Child_Frame_Dispatch.Direction_Code_Valid
              and then Last_Child_Frame_Dispatch.Reference_Queried
              and then Last_Child_Frame_Dispatch.Dispatch.Callback.Invoke
                .Registered_Dispatched;

            Runtime_Id_Frame :=
              A11y.Windows_Backend.UIA_COM_Live_Exports.Build_Interface_Frame
                (Fragment_Interface,
                 A11y.Windows_Backend.UIA_ABI_Surface
                   .Fragment_Get_Runtime_Id);
            Reply :=
              A11y.Windows_Backend.UIA_COM_Live_Exports
                .Dispatch_Interface_Frame_Access
                  (Object_Export_Table.all,
                   Runtime_Id_Frame,
                   Provider_Registry.all,
                   Snapshots,
                   Runtime_Id_Frame_Dispatch);
            Fragment_Runtime_Id_Dispatched :=
              Fragment_Last_Child_Frame_Dispatched
              and then Reply.Kind =
                A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
              and then Reply.HResult =
                A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
              and then Reply.Routed =
                A11y.Windows_Backend.UIA_Request_Router.Runtime_Id
              and then Runtime_Id_Frame_Dispatch.Direction_Code_Valid
              and then Runtime_Id_Frame_Dispatch.Dispatch.Callback.Invoke
                .Registered_Dispatched;

            Embedded_Fragment_Roots_Frame :=
              A11y.Windows_Backend.UIA_COM_Live_Exports.Build_Interface_Frame
                (Fragment_Interface,
                 A11y.Windows_Backend.UIA_ABI_Surface
                   .Fragment_Get_Embedded_Fragment_Roots);
            Reply :=
              A11y.Windows_Backend.UIA_COM_Live_Exports
                .Dispatch_Interface_Frame_Access
                  (Object_Export_Table.all,
                   Embedded_Fragment_Roots_Frame,
                   Provider_Registry.all,
                   Snapshots,
                   Embedded_Fragment_Roots_Frame_Dispatch);
            Embedded_Fragment_Roots_Dispatched :=
              Fragment_Runtime_Id_Dispatched
              and then Reply.Kind =
                A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
              and then Reply.HResult =
                A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
              and then Reply.Routed =
                A11y.Windows_Backend.UIA_Request_Router
                  .Embedded_Fragment_Roots_Empty
              and then Embedded_Fragment_Roots_Frame_Dispatch
                .Session_Code_Valid
              and then Embedded_Fragment_Roots_Frame_Dispatch
                .Provider_Code_Valid
              and then Embedded_Fragment_Roots_Frame_Dispatch
                .Object_Token_Valid
              and then Embedded_Fragment_Roots_Frame_Dispatch
                .Interface_Code_Valid
              and then Embedded_Fragment_Roots_Frame_Dispatch
                .Method_Code_Valid
              and then Embedded_Fragment_Roots_Frame_Dispatch
                .Reference_Queried
              and then Embedded_Fragment_Roots_Frame_Dispatch
                .Dispatch.Callback.Invoke.Registered_Dispatched;

            Fragment_Root_Frame :=
              A11y.Windows_Backend.UIA_COM_Live_Exports.Build_Interface_Frame
                (Fragment_Interface,
                 A11y.Windows_Backend.UIA_ABI_Surface
                   .Fragment_Get_Fragment_Root);
            Reply :=
              A11y.Windows_Backend.UIA_COM_Live_Exports
                .Dispatch_Interface_Frame_Access
                  (Object_Export_Table.all,
                   Fragment_Root_Frame,
                   Provider_Registry.all,
                   Snapshots,
                   Fragment_Root_Frame_Dispatch);
            Fragment_Root_Reply_Status := Reply.Status;
            Fragment_Root_Reply_Routed := Reply.Routed;
            if Reply.Payload.Kind =
              A11y.Windows_Backend.UIA_Request_Router.Fragment_Node
            then
               Fragment_Root_Reply_Node := Reply.Payload.Node;
            else
               Fragment_Root_Reply_Node := A11y.Node_Ids.No_Node;
            end if;
            Fragment_Root_Dispatched :=
              Embedded_Fragment_Roots_Dispatched
              and then Reply.Kind =
                A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
              and then Reply.HResult =
                A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
              and then Reply.Routed =
                A11y.Windows_Backend.UIA_Request_Router.Fragment_Node
              and then Reply.Payload.Node = Root
              and then Fragment_Root_Frame_Dispatch.Session_Code_Valid
              and then Fragment_Root_Frame_Dispatch.Provider_Code_Valid
              and then Fragment_Root_Frame_Dispatch.Object_Token_Valid
              and then Fragment_Root_Frame_Dispatch.Interface_Code_Valid
              and then Fragment_Root_Frame_Dispatch.Method_Code_Valid
              and then Fragment_Root_Frame_Dispatch.Reference_Queried
              and then Fragment_Root_Frame_Dispatch.Dispatch.Callback.Invoke
                .Registered_Dispatched;

            Root_Interface_Query := Public_Root_Export.Fragment_Root_Query;
            Root_Interface := Root_Interface_Query.Reference;
            Root_Interface_Queried :=
              Fragment_Root_Dispatched
              and then Root_Interface_Query.Object_Resolved
              and then Root_Interface_Query.Query.Supported
              and then Root_Interface.Present;

            Root_Point_Frame :=
              A11y.Windows_Backend.UIA_COM_Live_Exports.Build_Interface_Frame
                (Root_Interface,
                 A11y.Windows_Backend.UIA_ABI_Surface
                   .Fragment_Root_Element_Provider_From_Point,
                 Point => (X => 25, Y => 35));
            Reply :=
              A11y.Windows_Backend.UIA_COM_Live_Exports
                .Dispatch_Interface_Frame_Access
                  (Object_Export_Table.all,
                   Root_Point_Frame,
                   Provider_Registry.all,
                   Snapshots,
                   Root_Point_Frame_Dispatch);
            Root_Point_Dispatched :=
              Root_Interface_Queried
              and then Reply.Kind =
                A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
              and then Reply.HResult =
                A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
              and then Reply.Routed =
                A11y.Windows_Backend.UIA_Request_Router.Fragment_Node
              and then Reply.Payload.Node = Child
              and then Root_Point_Frame_Dispatch.Session_Code_Valid
              and then Root_Point_Frame_Dispatch.Provider_Code_Valid
              and then Root_Point_Frame_Dispatch.Object_Token_Valid
              and then Root_Point_Frame_Dispatch.Interface_Code_Valid
              and then Root_Point_Frame_Dispatch.Method_Code_Valid
              and then Root_Point_Frame_Dispatch.Reference_Queried
              and then Root_Point_Frame_Dispatch.Dispatch.Callback.Invoke
                .Registered_Dispatched;

            Root_Focus_Frame :=
              A11y.Windows_Backend.UIA_COM_Live_Exports.Build_Interface_Frame
                (Root_Interface,
                 A11y.Windows_Backend.UIA_ABI_Surface
                   .Fragment_Root_Get_Focus);
            Reply :=
              A11y.Windows_Backend.UIA_COM_Live_Exports
                .Dispatch_Interface_Frame_Access
                  (Object_Export_Table.all,
                   Root_Focus_Frame,
                   Provider_Registry.all,
                   Snapshots,
                   Root_Focus_Frame_Dispatch);
            Root_Focus_Dispatched :=
              Root_Point_Dispatched
              and then Reply.Kind =
                A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
              and then Reply.HResult =
                A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
              and then Reply.Routed =
                A11y.Windows_Backend.UIA_Request_Router.Fragment_Node
              and then Reply.Payload.Node = Child
              and then Root_Focus_Frame_Dispatch.Session_Code_Valid
              and then Root_Focus_Frame_Dispatch.Provider_Code_Valid
              and then Root_Focus_Frame_Dispatch.Object_Token_Valid
              and then Root_Focus_Frame_Dispatch.Interface_Code_Valid
              and then Root_Focus_Frame_Dispatch.Method_Code_Valid
              and then Root_Focus_Frame_Dispatch.Reference_Queried
              and then Root_Focus_Frame_Dispatch.Dispatch.Callback.Invoke
                .Registered_Dispatched;

            Simple_Interface_Query := Public_Root_Export.Simple_Query;
            Simple_Interface := Simple_Interface_Query.Reference;
            Provider_Options_Frame :=
              A11y.Windows_Backend.UIA_COM_Live_Exports.Build_Interface_Frame
                (Simple_Interface,
                 A11y.Windows_Backend.UIA_ABI_Surface
                   .Simple_Get_Provider_Options);
            Reply :=
              A11y.Windows_Backend.UIA_COM_Live_Exports
                .Dispatch_Interface_Frame_Access
                  (Object_Export_Table.all,
                   Provider_Options_Frame,
                   Provider_Registry.all,
                   Snapshots,
                   Provider_Options_Frame_Dispatch);
            Provider_Options_Dispatched :=
              Root_Focus_Dispatched
              and then Simple_Interface_Query.Object_Resolved
              and then Simple_Interface_Query.Query.Supported
              and then Simple_Interface.Present
              and then Reply.Kind =
                A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
              and then Reply.HResult =
                A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
              and then Reply.Routed =
                A11y.Windows_Backend.UIA_Request_Router.Provider_Options
              and then Reply.Payload.Options = 1
              and then Provider_Options_Frame_Dispatch.Session_Code_Valid
              and then Provider_Options_Frame_Dispatch.Provider_Code_Valid
              and then Provider_Options_Frame_Dispatch.Object_Token_Valid
              and then Provider_Options_Frame_Dispatch.Interface_Code_Valid
              and then Provider_Options_Frame_Dispatch.Method_Code_Valid
              and then Provider_Options_Frame_Dispatch.Reference_Queried
              and then Provider_Options_Frame_Dispatch.Dispatch.Callback.Invoke
                .Registered_Dispatched;

            Host_Raw_Element_Provider_Frame :=
              A11y.Windows_Backend.UIA_COM_Live_Exports.Build_Interface_Frame
                (Simple_Interface,
                 A11y.Windows_Backend.UIA_ABI_Surface
                   .Simple_Get_Host_Raw_Element_Provider);
            Reply :=
              A11y.Windows_Backend.UIA_COM_Live_Exports
                .Dispatch_Interface_Frame_Access
                  (Object_Export_Table.all,
                   Host_Raw_Element_Provider_Frame,
                   Provider_Registry.all,
                   Snapshots,
                   Host_Raw_Element_Provider_Frame_Dispatch);
            Host_Raw_Element_Provider_Dispatched :=
              Provider_Options_Dispatched
              and then Reply.Kind =
                A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
              and then Reply.HResult =
                A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
              and then Reply.Routed =
                A11y.Windows_Backend.UIA_Request_Router
                  .Host_Raw_Element_Provider_Empty
              and then Host_Raw_Element_Provider_Frame_Dispatch
                .Session_Code_Valid
              and then Host_Raw_Element_Provider_Frame_Dispatch
                .Provider_Code_Valid
              and then Host_Raw_Element_Provider_Frame_Dispatch
                .Object_Token_Valid
              and then Host_Raw_Element_Provider_Frame_Dispatch
                .Interface_Code_Valid
              and then Host_Raw_Element_Provider_Frame_Dispatch
                .Method_Code_Valid
              and then Host_Raw_Element_Provider_Frame_Dispatch
                .Reference_Queried
              and then Host_Raw_Element_Provider_Frame_Dispatch
                .Dispatch.Callback.Invoke.Registered_Dispatched;

            Pattern_Provider_Frame :=
              A11y.Windows_Backend.UIA_COM_Live_Exports.Build_Interface_Frame
                (Simple_Interface,
                 A11y.Windows_Backend.UIA_ABI_Surface
                   .Simple_Get_Pattern_Provider);
            Reply :=
              A11y.Windows_Backend.UIA_COM_Live_Exports
                .Dispatch_Interface_Frame_Access
                  (Object_Export_Table.all,
                   Pattern_Provider_Frame,
                   Provider_Registry.all,
                   Snapshots,
                   Pattern_Provider_Frame_Dispatch);
            Pattern_Provider_Frame_Dispatched :=
              Host_Raw_Element_Provider_Dispatched
              and then Reply.Kind =
                A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
              and then Reply.HResult =
                A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
              and then Reply.Routed =
                A11y.Windows_Backend.UIA_Request_Router.Pattern_Set
              and then Reply.Payload.Patterns
                (A11y.Windows_Backend.UIA_Actions.Invoke)
              and then Reply.Payload.Patterns
                (A11y.Windows_Backend.UIA_Actions.Toggle)
              and then Pattern_Provider_Frame_Dispatch.Session_Code_Valid
              and then Pattern_Provider_Frame_Dispatch.Provider_Code_Valid
              and then Pattern_Provider_Frame_Dispatch.Object_Token_Valid
              and then Pattern_Provider_Frame_Dispatch.Interface_Code_Valid
              and then Pattern_Provider_Frame_Dispatch.Method_Code_Valid
              and then Pattern_Provider_Frame_Dispatch.Reference_Queried
              and then Pattern_Provider_Frame_Dispatch.Dispatch.Callback.Invoke
                .Registered_Dispatched;

            Bounding_Rectangle_Frame :=
              A11y.Windows_Backend.UIA_COM_Live_Exports.Build_Interface_Frame
                (Fragment_Interface,
                 A11y.Windows_Backend.UIA_ABI_Surface
                   .Fragment_Get_Bounding_Rectangle);
            Reply :=
              A11y.Windows_Backend.UIA_COM_Live_Exports
                .Dispatch_Interface_Frame_Access
                  (Object_Export_Table.all,
                   Bounding_Rectangle_Frame,
                   Provider_Registry.all,
                   Snapshots,
                   Bounding_Rectangle_Frame_Dispatch);
            Bounding_Rectangle_Reply_Status := Reply.Status;
            Bounding_Rectangle_Reply_Routed := Reply.Routed;
            Bounding_Rectangle_Matches :=
              Reply.Routed =
                A11y.Windows_Backend.UIA_Request_Router.Property_Rectangle
              and then Reply.Payload.Bounds =
                Snapshots.all.Properties.Bounds;
            Bounding_Rectangle_Frame_Dispatched :=
              Pattern_Provider_Frame_Dispatched
              and then Reply.Kind =
                A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
              and then Reply.HResult =
                A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
              and then Reply.Routed =
                A11y.Windows_Backend.UIA_Request_Router.Property_Rectangle
              and then Reply.Payload.Bounds =
                Snapshots.all.Properties.Bounds
              and then Bounding_Rectangle_Frame_Dispatch
                .Session_Code_Valid
              and then Bounding_Rectangle_Frame_Dispatch
                .Provider_Code_Valid
              and then Bounding_Rectangle_Frame_Dispatch
                .Object_Token_Valid
              and then Bounding_Rectangle_Frame_Dispatch
                .Interface_Code_Valid
              and then Bounding_Rectangle_Frame_Dispatch
                .Method_Code_Valid
              and then Bounding_Rectangle_Frame_Dispatch
                .Reference_Queried
              and then Bounding_Rectangle_Frame_Dispatch
                .Dispatch.Callback.Invoke.Registered_Dispatched;

            Property_Frame :=
              A11y.Windows_Backend.UIA_COM_Live_Exports.Build_Interface_Frame
                (Simple_Interface,
                 A11y.Windows_Backend.UIA_ABI_Surface
                   .Simple_Get_Property_Value);
            Reply :=
              A11y.Windows_Backend.UIA_COM_Live_Exports
                .Dispatch_Interface_Frame_Access
                  (Object_Export_Table.all,
                   Property_Frame,
                   Provider_Registry.all,
                   Snapshots,
                   Property_Frame_Dispatch);
            Simple_Property_Frame_Dispatched :=
              Bounding_Rectangle_Frame_Dispatched
              and then Simple_Interface_Query.Object_Resolved
              and then Simple_Interface_Query.Query.Supported
              and then Simple_Interface.Present
              and then Reply.Kind =
                A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
              and then Reply.HResult =
                A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
              and then Reply.Routed =
                A11y.Windows_Backend.UIA_Request_Router.Property_String
              and then To_String (Reply.Payload.Text) =
                "External UIA Probe"
              and then Property_Frame_Dispatch.Session_Code_Valid
              and then Property_Frame_Dispatch.Provider_Code_Valid
              and then Property_Frame_Dispatch.Object_Token_Valid
              and then Property_Frame_Dispatch.Interface_Code_Valid
              and then Property_Frame_Dispatch.Method_Code_Valid
              and then Property_Frame_Dispatch.Reference_Queried
              and then Property_Frame_Dispatch.Dispatch.Callback.Invoke
                .Registered_Dispatched;

            Action_Frame :=
              A11y.Windows_Backend.UIA_COM_Live_Exports.Build_Interface_Frame
                (Fragment_Interface,
                 A11y.Windows_Backend.UIA_ABI_Surface.Fragment_Set_Focus);
            Reply :=
              A11y.Windows_Backend.UIA_COM_Live_Exports
                .Dispatch_Interface_Frame_Access
                  (Object_Export_Table.all,
                   Action_Frame,
                   Provider_Registry.all,
                   Snapshots,
                   Action_Frame_Dispatch);
            Fragment_Action_Frame_Status := Reply.Status;
            Fragment_Action_Frame_Routed := Reply.Routed;
            Fragment_Action_Frame_Dispatched :=
              Simple_Property_Frame_Dispatched
              and then Reply.Kind =
                A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
              and then Reply.HResult =
                A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
              and then Reply.Routed =
                A11y.Windows_Backend.UIA_Request_Router.Action_Request
              and then Reply.Payload.Requested_Action =
                A11y.Actions.Set_Focus
              and then Action_Frame_Dispatch.Session_Code_Valid
              and then Action_Frame_Dispatch.Provider_Code_Valid
              and then Action_Frame_Dispatch.Object_Token_Valid
              and then Action_Frame_Dispatch.Interface_Code_Valid
              and then Action_Frame_Dispatch.Method_Code_Valid
              and then Action_Frame_Dispatch.Reference_Queried
              and then Action_Frame_Dispatch.Dispatch.Callback.Invoke
                .Registered_Dispatched;
            Fragment_Set_Focus_Payload_Preserved :=
              Fragment_Action_Frame_Dispatched
              and then Reply.Payload.Requested_Action =
                A11y.Actions.Set_Focus;

            A11y.Windows_Backend.UIA_COM_Live_Exports.Release
              (Fragment_Interface, Release_Report);
            Reply :=
              A11y.Windows_Backend.UIA_COM_Live_Exports
                .Dispatch_Interface_Method_Access
                  (Object_Export_Table.all,
                   Fragment_Interface,
                   A11y.Windows_Backend.UIA_ABI_Surface.Fragment_Navigate,
                   Provider_Registry.all,
                   Snapshots,
                   Released_Dispatch,
                   A11y.Windows_Backend.UIA_Fragments.First_Child);
            Released_Interface_Rejected :=
              Fragment_Action_Frame_Dispatched
              and then Release_Report.Reference_Released_After
              and then Reply.Kind =
                A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
              and then Reply.Status = A11y.Results.Node_Unavailable
              and then not Released_Dispatch.Callback_Dispatched;

            if Released_Interface_Rejected then
               A11y.Windows_Backend.UIA_COM_Object_Exports.Release_Object
                 (Object_Export_Table.all, Object_Export.Token,
                  Object_Release);
               Object_Token_Released :=
                 Object_Release.Released
                 and then Object_Release.Status = A11y.Results.Success
                 and then Object_Release.Tombstone_Added;

               A11y.Windows_Backend.UIA_COM_Object_Exports.Resolve_Object
                 (Object_Export_Table.all,
                  Object_Export.Token,
                  Session,
                  Provider_Id,
                  Released_Object_Resolve);
               Released_Object_Token_Rejected :=
                 Object_Token_Released
                 and then not Released_Object_Resolve.Found
                 and then Released_Object_Resolve.Released
                 and then Released_Object_Resolve.Status =
                   A11y.Results.Node_Unavailable;
            end if;

            if not Object_Token_Released then
               Boundary_Status := Object_Release.Status;
            elsif not Released_Object_Token_Rejected then
               Boundary_Status := Released_Object_Resolve.Status;
            end if;
         end if;
      end if;

      Ada.Text_IO.Put_Line ("{");
      Ada.Text_IO.Put_Line
        ("  ""schema"": ""org.a11y.native_client_uia_external_client.v1"",");
      Ada.Text_IO.Put_Line ("  ""platform"": ""Windows"",");
      Ada.Text_IO.Put_Line ("  ""native_api"": ""UI Automation"",");
      Ada.Text_IO.Put_Line
        ("  ""native_bridge_compiled_for_windows"": "
         & (if Bridge_Target_Is_Windows then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_bridge_stub_runtime"": "
         & (if Bridge_Target_Is_Windows then "false" else "true")
         & ",");
      Ada.Text_IO.Put_Line ("  ""client_process"": ""native_client_uia"",");
      Ada.Text_IO.Put_Line
        ("  ""probe"": ""external_uia_client_traverses_com_fragment_root"",");
      Ada.Text_IO.Put_Line
        ("  ""required_native_boundary"": ""live_uia_com_provider_export"",");
      Ada.Text_IO.Put_Line
        ("  ""next_required_evidence"": ""external_uia_client_traverses_com_fragment_root"",");
      Ada.Text_IO.Put_Line
        ("  ""transport_status"": "
         & Q
             (if External_Client_Traversal_Observed
              then "native_client_available"
              else "blocked_transport_unavailable")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_client_runtime_probed"": "
         & (if Client_Runtime_Probed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_client_runtime_available"": "
         & (if Client_Runtime_Available then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_client_coinitialized"": "
         & (if Client_Runtime_Probe.Coinitialized /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_client_automation_created"": "
         & (if Client_Runtime_Probe.Automation_Created /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_client_root_element_obtained"": "
         & (if Client_Runtime_Probe.Root_Element_Obtained /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_client_root_name_obtained"": "
         & (if Client_Runtime_Probe.Root_Name_Obtained /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_client_coinitialize_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Client_Runtime_Probe.CoInitialize_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_client_cocreate_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Client_Runtime_Probe.CoCreate_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_client_get_root_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Client_Runtime_Probe.Get_Root_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_client_get_name_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Client_Runtime_Probe.Get_Name_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_host_window_probed"": "
         & (if Host_Window_Probed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_host_window_handshake_available"": "
         & (if Host_Window_Handshake_Available then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_host_window_class_registered"": "
         & (if Host_Window_Probe.Window_Class_Registered /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_host_window_created"": "
         & (if Host_Window_Probe.Window_Created /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_host_window_wm_getobject_sent"": "
         & (if Host_Window_Probe.WM_GetObject_Sent /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_host_window_root_object_id_matched"": "
         & (if Host_Window_Probe.UIA_Root_Object_Id_Matched /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_host_window_return_provider_called"": "
         & (if Host_Window_Probe.Return_Raw_Element_Provider_Called /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_host_window_null_provider_returned_zero"": "
         & (if Host_Window_Probe.Null_Provider_Returned_Zero /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_host_window_destroyed"": "
         & (if Host_Window_Probe.Window_Destroyed /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_host_window_register_error"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Host_Window_Probe.Register_Error)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_host_window_create_error"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Host_Window_Probe.Create_Error)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_host_window_return_provider_lresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Host_Window_Probe
                        .Return_Raw_Element_Provider_LResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_minimal_provider_probed"": "
         & (if Minimal_Provider_Probed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_minimal_provider_host_window_available"": "
         & (if Minimal_Provider_Host_Window_Available
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_minimal_provider_coinitialized"": "
         & (if Minimal_Provider_Probe.Coinitialized /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_minimal_provider_window_class_registered"": "
         & (if Minimal_Provider_Probe.Window_Class_Registered /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_minimal_provider_window_created"": "
         & (if Minimal_Provider_Probe.Window_Created /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_minimal_provider_created"": "
         & (if Minimal_Provider_Probe.Provider_Created /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_minimal_provider_wm_getobject_sent"": "
         & (if Minimal_Provider_Probe.WM_GetObject_Sent /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_minimal_provider_root_object_id_matched"": "
         & (if Minimal_Provider_Probe.UIA_Root_Object_Id_Matched /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_minimal_provider_return_provider_called"": "
         & (if Minimal_Provider_Probe.Return_Raw_Element_Provider_Called /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_minimal_provider_return_provider_nonzero"": "
         & (if Minimal_Provider_Probe.Return_Raw_Element_Provider_Nonzero /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_minimal_provider_query_interface_called"": "
         & (if Minimal_Provider_Probe.Provider_Query_Interface_Called /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_minimal_provider_add_ref_called"": "
         & (if Minimal_Provider_Probe.Provider_Add_Ref_Called /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_minimal_provider_release_called"": "
         & (if Minimal_Provider_Probe.Provider_Release_Called /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_minimal_provider_options_called"": "
         & (if Minimal_Provider_Probe.Provider_Options_Called /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_minimal_provider_element_from_handle_called"": "
         & (if Minimal_Provider_Probe.Element_From_Handle_Called /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_minimal_provider_element_from_handle_succeeded"": "
         & (if Minimal_Provider_Probe.Element_From_Handle_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_minimal_provider_window_destroyed"": "
         & (if Minimal_Provider_Probe.Window_Destroyed /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_minimal_provider_final_ref_count"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt32'Image
                     (Minimal_Provider_Probe.Provider_Final_Ref_Count)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_minimal_provider_coinitialize_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Minimal_Provider_Probe.CoInitialize_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_minimal_provider_register_error"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Minimal_Provider_Probe.Register_Error)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_minimal_provider_create_error"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Minimal_Provider_Probe.Create_Error)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_minimal_provider_return_provider_lresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Minimal_Provider_Probe
                        .Return_Raw_Element_Provider_LResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_minimal_provider_cocreate_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Minimal_Provider_Probe.CoCreate_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_minimal_provider_element_from_handle_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Minimal_Provider_Probe.Element_From_Handle_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_probed"": "
         & (if Callback_Provider_Probed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_host_window_available"": "
         & (if Callback_Provider_Host_Window_Available
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_coinitialized"": "
         & (if Callback_Provider_Probe.Coinitialized /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_window_created"": "
         & (if Callback_Provider_Probe.Window_Created /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_created"": "
         & (if Callback_Provider_Probe.Provider_Created /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_wm_getobject_sent"": "
         & (if Callback_Provider_Probe.WM_GetObject_Sent /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_root_object_id_matched"": "
         & (if Callback_Provider_Probe.UIA_Root_Object_Id_Matched /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_return_provider_called"": "
         & (if Callback_Provider_Probe.Return_Raw_Element_Provider_Called /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_return_provider_nonzero"": "
         & (if Callback_Provider_Probe.Return_Raw_Element_Provider_Nonzero /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_query_interface_called"": "
         & (if Callback_Provider_Probe.Provider_Query_Interface_Called /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_add_ref_called"": "
         & (if Callback_Provider_Probe.Provider_Add_Ref_Called /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_release_called"": "
         & (if Callback_Provider_Probe.Provider_Release_Called /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_options_called"": "
         & (if Callback_Provider_Probe.Provider_Options_Called /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_options_callback_called"": "
         & (if Callback_Provider_Probe.Provider_Options_Callback_Called /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_options_callback_succeeded"": "
         & (if Callback_Provider_Probe.Provider_Options_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_pattern_provider_called"": "
         & (if Callback_Provider_Probe.Pattern_Provider_Called /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_pattern_provider_callback_called"": "
         & (if Callback_Provider_Probe.Pattern_Provider_Callback_Called /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_pattern_provider_callback_succeeded"": "
         & (if Callback_Provider_Probe.Pattern_Provider_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_pattern_provider_support_callback_called"": "
         & (if Callback_Provider_Probe
              .Pattern_Provider_Support_Callback_Called /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_pattern_provider_support_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Pattern_Provider_Support_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_pattern_provider_returned_invoke"": "
         & (if Callback_Provider_Probe.Pattern_Provider_Returned_Invoke /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_pattern_provider_returned_toggle"": "
         & (if Callback_Provider_Probe.Pattern_Provider_Returned_Toggle /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_pattern_provider_returned_expand_collapse"": "
         & (if Callback_Provider_Probe
              .Pattern_Provider_Returned_Expand_Collapse /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_pattern_provider_returned_scroll_item"": "
         & (if Callback_Provider_Probe
              .Pattern_Provider_Returned_Scroll_Item /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_pattern_provider_returned_selection_item"": "
         & (if Callback_Provider_Probe
              .Pattern_Provider_Returned_Selection_Item /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_pattern_provider_returned_range_value"": "
         & (if Callback_Provider_Probe
              .Pattern_Provider_Returned_Range_Value /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_pattern_provider_returned_window"": "
         & (if Callback_Provider_Probe.Pattern_Provider_Returned_Window /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_invoke_provider_invoke_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Invoke_Provider_Invoke_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_toggle_provider_toggle_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Toggle_Provider_Toggle_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_toggle_provider_get_state_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Toggle_Provider_Get_State_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_toggle_provider_state"": """
         & Trimmed
             (Natural'Image
                (Natural (Callback_Provider_Probe.Toggle_Provider_State)))
         & """,");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_expand_collapse_provider_expand_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Expand_Collapse_Provider_Expand_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_expand_collapse_provider_collapse_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Expand_Collapse_Provider_Collapse_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_expand_collapse_provider_get_state_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Expand_Collapse_Provider_Get_State_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_expand_collapse_provider_state"": """
         & Trimmed
             (Natural'Image
                (Natural
                   (Callback_Provider_Probe.Expand_Collapse_Provider_State)))
         & """,");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_scroll_item_provider_scroll_into_view_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Scroll_Item_Provider_Scroll_Into_View_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_selection_item_provider_select_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Selection_Item_Provider_Select_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_selection_item_provider_add_to_selection_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Selection_Item_Provider_Add_To_Selection_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_selection_item_provider_remove_from_selection_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Selection_Item_Provider_Remove_From_Selection_Callback_Succeeded
              /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_selection_item_provider_get_is_selected_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Selection_Item_Provider_Get_Is_Selected_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_selection_item_provider_is_selected"": "
         & (if Callback_Provider_Probe.Selection_Item_Provider_Is_Selected /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_selection_item_provider_get_selection_container_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Selection_Item_Provider_Get_Selection_Container_Callback_Succeeded
              /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_selection_item_provider_returned_selection_container"": "
         & (if Callback_Provider_Probe
              .Selection_Item_Provider_Returned_Selection_Container /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_range_value_provider_set_value_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Range_Value_Provider_Set_Value_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_range_value_provider_get_value_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Range_Value_Provider_Get_Value_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_range_value_provider_get_is_read_only_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Range_Value_Provider_Get_Is_Read_Only_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_range_value_provider_get_maximum_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Range_Value_Provider_Get_Maximum_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_range_value_provider_get_minimum_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Range_Value_Provider_Get_Minimum_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_range_value_provider_get_large_change_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Range_Value_Provider_Get_Large_Change_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_range_value_provider_get_small_change_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Range_Value_Provider_Get_Small_Change_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_window_provider_close_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Window_Provider_Close_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_window_provider_get_can_maximize_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Window_Provider_Get_Can_Maximize_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_window_provider_get_can_minimize_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Window_Provider_Get_Can_Minimize_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_window_provider_get_is_modal_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Window_Provider_Get_Is_Modal_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_window_provider_get_visual_state_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Window_Provider_Get_Visual_State_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_window_provider_get_interaction_state_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Window_Provider_Get_Interaction_State_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_advise_events_advise_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Advise_Events_Advise_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_advise_events_unadvise_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Advise_Events_Unadvise_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_property_value_called"": "
         & (if Callback_Provider_Probe.Property_Value_Called /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_property_value_callback_called"": "
         & (if Callback_Provider_Probe.Property_Value_Callback_Called /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_property_value_callback_succeeded"": "
         & (if Callback_Provider_Probe.Property_Value_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_host_raw_element_provider_called"": "
         & (if Callback_Provider_Probe.Host_Raw_Element_Provider_Called /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_host_raw_element_provider_callback_called"": "
         & (if Callback_Provider_Probe
              .Host_Raw_Element_Provider_Callback_Called /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_host_raw_element_provider_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Host_Raw_Element_Provider_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_host_raw_element_provider_returned_host"": "
         & (if Callback_Provider_Probe
              .Host_Raw_Element_Provider_Returned_Host /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_fragment_query_interface_succeeded"": "
         & (if Callback_Provider_Probe
              .Fragment_Query_Interface_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_fragment_navigate_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Fragment_Navigate_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_fragment_runtime_id_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Fragment_Runtime_Id_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_fragment_bounding_rectangle_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Fragment_Bounding_Rectangle_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_fragment_embedded_roots_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Fragment_Embedded_Roots_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_fragment_set_focus_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Fragment_Set_Focus_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_fragment_root_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Fragment_Root_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_fragment_root_query_interface_succeeded"": "
         & (if Callback_Provider_Probe
              .Fragment_Root_Query_Interface_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_root_from_point_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Root_From_Point_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_root_from_point_returned_fragment"": "
         & (if Callback_Provider_Probe
              .Root_From_Point_Returned_Fragment /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_root_get_focus_callback_succeeded"": "
         & (if Callback_Provider_Probe
              .Root_Get_Focus_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_root_get_focus_returned_fragment"": "
         & (if Callback_Provider_Probe
              .Root_Get_Focus_Returned_Fragment /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_full_frame_callback_called"": "
         & (if Callback_Provider_Probe.Full_Frame_Callback_Called /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_full_frame_callback_succeeded"": "
         & (if Callback_Provider_Probe.Full_Frame_Callback_Succeeded /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_window_destroyed"": "
         & (if Callback_Provider_Probe.Window_Destroyed /= 0
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_options_callback_session"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt64'Image
                     (Callback_Provider_Probe.Options_Callback_Session)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_options_callback_provider"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt64'Image
                     (Callback_Provider_Probe.Options_Callback_Provider)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_options_callback_method"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt32'Image
                     (Callback_Provider_Probe.Options_Callback_Method)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_options_callback_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt32'Image
                     (Callback_Provider_Probe.Options_Callback_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_pattern_callback_session"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt64'Image
                     (Callback_Provider_Probe.Pattern_Callback_Session)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_pattern_callback_provider"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt64'Image
                     (Callback_Provider_Probe.Pattern_Callback_Provider)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_pattern_callback_method"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt32'Image
                     (Callback_Provider_Probe.Pattern_Callback_Method)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_pattern_callback_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt32'Image
                     (Callback_Provider_Probe.Pattern_Callback_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_property_callback_session"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt64'Image
                     (Callback_Provider_Probe.Property_Callback_Session)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_property_callback_provider"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt64'Image
                     (Callback_Provider_Probe.Property_Callback_Provider)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_property_callback_method"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt32'Image
                     (Callback_Provider_Probe.Property_Callback_Method)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_property_callback_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt32'Image
                     (Callback_Provider_Probe.Property_Callback_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_host_callback_session"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt64'Image
                     (Callback_Provider_Probe.Host_Callback_Session)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_host_callback_provider"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt64'Image
                     (Callback_Provider_Probe.Host_Callback_Provider)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_host_callback_method"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt32'Image
                     (Callback_Provider_Probe.Host_Callback_Method)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_host_callback_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt32'Image
                     (Callback_Provider_Probe.Host_Callback_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_full_frame_simple_count"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt32'Image
                     (Callback_Provider_Probe.Full_Frame_Simple_Count)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_full_frame_fragment_count"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt32'Image
                     (Callback_Provider_Probe.Full_Frame_Fragment_Count)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_full_frame_root_count"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt32'Image
                     (Callback_Provider_Probe.Full_Frame_Root_Count)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_full_frame_advise_events_count"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt32'Image
                     (Callback_Provider_Probe.Full_Frame_Advise_Events_Count)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_full_frame_session"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt64'Image
                     (Callback_Provider_Probe.Full_Frame_Session)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_full_frame_provider"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt64'Image
                     (Callback_Provider_Probe.Full_Frame_Provider)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_full_frame_object_token"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt64'Image
                     (Callback_Provider_Probe.Full_Frame_Object_Token)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_full_frame_interface"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt64'Image
                     (Callback_Provider_Probe.Full_Frame_Interface)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_full_frame_method"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt64'Image
                     (Callback_Provider_Probe.Full_Frame_Method)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_full_frame_direction"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt64'Image
                     (Callback_Provider_Probe.Full_Frame_Direction)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_full_frame_point_x"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt64'Image
                     (Callback_Provider_Probe.Full_Frame_Point_X)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_full_frame_point_y"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt64'Image
                     (Callback_Provider_Probe.Full_Frame_Point_Y)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_full_frame_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt32'Image
                     (Callback_Provider_Probe.Full_Frame_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_final_ref_count"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_UInt32'Image
                     (Callback_Provider_Probe.Provider_Final_Ref_Count)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_coinitialize_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Callback_Provider_Probe.CoInitialize_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_return_provider_lresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Callback_Provider_Probe
                        .Return_Raw_Element_Provider_LResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_options_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Callback_Provider_Probe.Provider_Options_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_property_value_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Callback_Provider_Probe.Property_Value_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_pattern_provider_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Callback_Provider_Probe.Pattern_Provider_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_invoke_provider_invoke_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Callback_Provider_Probe
                        .Invoke_Provider_Invoke_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_toggle_provider_toggle_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Callback_Provider_Probe
                        .Toggle_Provider_Toggle_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_host_raw_element_provider_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Callback_Provider_Probe
                        .Host_Raw_Element_Provider_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_fragment_navigate_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Callback_Provider_Probe.Fragment_Navigate_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_fragment_runtime_id_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Callback_Provider_Probe.Fragment_Runtime_Id_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_fragment_bounding_rectangle_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Callback_Provider_Probe
                        .Fragment_Bounding_Rectangle_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_fragment_embedded_roots_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Callback_Provider_Probe.Fragment_Embedded_Roots_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_fragment_set_focus_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Callback_Provider_Probe.Fragment_Set_Focus_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_fragment_root_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Callback_Provider_Probe.Fragment_Root_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_root_from_point_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Callback_Provider_Probe.Root_From_Point_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_callback_provider_root_get_focus_hresult"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Native_Bridge
                   .Native_HResult'Image
                     (Callback_Provider_Probe.Root_Get_Focus_HResult)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""failure_stage"": " & Q (Failure_Stage) & ",");
      Ada.Text_IO.Put_Line
        ("  ""provider_export_observed"": "
         & (if Provider_Export_Observed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_public_root_export_path_observed"": "
         & (if Public_Root_Export.Status = A11y.Results.Success
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_public_root_provider_ensured"": "
         & (if Public_Root_Export.Provider_Ensured
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_public_root_provider_initialized"": "
         & (if Public_Root_Export.Provider_Initialized
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_public_root_object_exported"": "
         & (if Public_Root_Export.Object_Exported
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_public_root_native_node_component_stable"": "
         & (if Public_Root_Export.Native_Node_Component_Stable
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_public_root_fragment_queryable"": "
         & (if Public_Root_Export.Fragment_Interface_Queryable
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_public_root_simple_queryable"": "
         & (if Public_Root_Export.Simple_Interface_Queryable
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""windows_uia_public_root_fragment_root_queryable"": "
         & (if Public_Root_Export.Fragment_Root_Interface_Queryable
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_interface_queried"": "
         & (if Fragment_Interface_Queried then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_navigate_dispatched"": "
         & (if Fragment_Navigate_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_navigate_reply_status"": "
         & Q (Status_Name (Fragment_Navigate_Reply_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_navigate_reply_routed"": "
         & Q
             (A11y.Windows_Backend.UIA_Request_Router
                .Routed_Reply_Kind'Image (Fragment_Navigate_Reply_Routed))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_navigate_object_resolved"": "
         & (if Navigate_Dispatch.all.Object_Resolved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_navigate_interface_accepted"": "
         & (if Navigate_Dispatch.all.Interface_Accepted
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_navigate_method_allowed"": "
         & (if Navigate_Dispatch.all.Method_Allowed_For_Interface
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_navigate_frame_prepared"": "
         & (if Navigate_Dispatch.all.Frame_Prepared then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_navigate_frame_matches_export"": "
         & (if Navigate_Dispatch.all.Callback.Frame_Matches_Export
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_navigate_method_code_valid"": "
         & (if Navigate_Dispatch.all.Callback.Method_Code_Valid
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_navigate_registered_dispatched"": "
         & (if Navigate_Dispatch.all.Callback.Invoke.Registered_Dispatched
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_navigate_callback_allowed"": "
         & (if Navigate_Dispatch.all.Callback.Invoke.Callback_Allowed
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_navigate_method_dispatchable"": "
         & (if Navigate_Dispatch.all.Callback.Invoke.Method_Dispatchable
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_navigate_request_prepared"": "
         & (if Navigate_Dispatch.all.Callback.Invoke.Request_Prepared
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_navigate_registered_call_attempted"": "
         & (if Navigate_Dispatch.all.Callback.Invoke.Registered_Call_Attempted
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_navigate_dispatch_stage"": "
         & Trimmed
             (Natural'Image
                (Navigate_Dispatch.all.Callback.Invoke.Dispatch_Stage))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_navigate_boundary_stage"": "
         & Trimmed
             (Natural'Image
                (Navigate_Dispatch.all.Callback.Invoke.Boundary_Report
                   .Boundary_Stage))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_navigate_boundary_interface_supported"": "
         & (if Navigate_Dispatch.all.Callback.Invoke.Boundary_Report
                .Interface_Supported
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_navigate_boundary_resolved"": "
         & (if Navigate_Dispatch.all.Callback.Invoke.Boundary_Report.Resolved
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_navigate_boundary_native_identity_prepared"": "
         & (if Navigate_Dispatch.all.Callback.Invoke.Boundary_Report
                .Native_Identity_Prepared
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_navigate_boundary_native_admitted"": "
         & (if Navigate_Dispatch.all.Callback.Invoke.Boundary_Report
                .Native_Admitted
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_navigate_boundary_native_completed"": "
         & (if Navigate_Dispatch.all.Callback.Invoke.Boundary_Report
                .Native_Completed
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_navigate_boundary_reply_status"": "
         & Q
             (Status_Name
                (Navigate_Dispatch.all.Callback.Invoke.Boundary_Report
                   .Reply_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_navigate_boundary_final_status"": "
         & Q
             (Status_Name
                (Navigate_Dispatch.all.Callback.Invoke.Boundary_Report
                   .Final_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_last_child_frame_dispatched"": "
         & (if Fragment_Last_Child_Frame_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_runtime_id_dispatched"": "
         & (if Fragment_Runtime_Id_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""embedded_fragment_roots_dispatched"": "
         & (if Embedded_Fragment_Roots_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_root_dispatched"": "
         & (if Fragment_Root_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_root_reply_status"": "
         & Q (Status_Name (Fragment_Root_Reply_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_root_reply_routed"": "
         & Q
             (A11y.Windows_Backend.UIA_Request_Router
                .Routed_Reply_Kind'Image (Fragment_Root_Reply_Routed))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_root_reply_node"": "
         & Q (Natural'Image (A11y.Node_Ids.To_Natural
              (Fragment_Root_Reply_Node)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""root_interface_queried"": "
         & (if Root_Interface_Queried then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""root_point_dispatched"": "
         & (if Root_Point_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""root_focus_dispatched"": "
         & (if Root_Focus_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""provider_options_dispatched"": "
         & (if Provider_Options_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""host_raw_element_provider_dispatched"": "
         & (if Host_Raw_Element_Provider_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""pattern_provider_frame_dispatched"": "
         & (if Pattern_Provider_Frame_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""bounding_rectangle_frame_dispatched"": "
         & (if Bounding_Rectangle_Frame_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""bounding_rectangle_reply_status"": "
         & Q (Status_Name (Bounding_Rectangle_Reply_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""bounding_rectangle_reply_routed"": "
         & Q
             (A11y.Windows_Backend.UIA_Request_Router
                .Routed_Reply_Kind'Image (Bounding_Rectangle_Reply_Routed))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""bounding_rectangle_matches"": "
         & (if Bounding_Rectangle_Matches then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""bounding_rectangle_registered_dispatched"": "
         & (if Bounding_Rectangle_Frame_Dispatch.Dispatch.Callback.Invoke
                .Registered_Dispatched
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""bounding_rectangle_boundary_stage"": "
         & Trimmed
             (Natural'Image
                (Bounding_Rectangle_Frame_Dispatch.Dispatch.Callback.Invoke
                   .Boundary_Report.Boundary_Stage))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""simple_property_frame_dispatched"": "
         & (if Simple_Property_Frame_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_action_frame_dispatched"": "
         & (if Fragment_Action_Frame_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_action_frame_status"": "
         & Q (Status_Name (Fragment_Action_Frame_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_action_frame_routed"": "
         & Q
             (Trimmed
                (A11y.Windows_Backend.UIA_Request_Router
                   .Routed_Reply_Kind'Image
                     (Fragment_Action_Frame_Routed)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fragment_set_focus_payload_preserved"": "
         & (if Fragment_Set_Focus_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""released_interface_rejected"": "
         & (if Released_Interface_Rejected then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""object_token_released"": "
         & (if Object_Token_Released then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""released_object_token_rejected"": "
         & (if Released_Object_Token_Rejected then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""com_live_chain_observed"": "
         & (if COM_Live_Chain_Observed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""metadata_name_preserved"": "
         & (if Metadata_Name_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""metadata_identifier_preserved"": "
         & (if Metadata_Identifier_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""metadata_help_preserved"": "
         & (if Metadata_Help_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""metadata_placeholder_preserved"": "
         & (if Metadata_Placeholder_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""metadata_detail_preserved"": "
         & (if Metadata_Detail_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""metadata_group_preserved"": "
         & (if Metadata_Group_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""protected_value_suppressed"": "
         & (if Protected_Value_Suppressed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""privacy_boundary_observed"": "
         & (if Privacy_Boundary_Observed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""internal_native_export_chain_ready"": "
         & (if Internal_Native_Export_Chain_Ready
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""external_client_traversal_observed"": "
         & (if External_Client_Traversal_Observed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""semantic_state_mutated"": "
         & (if Semantic_State_Mutated then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_conformance_ready"": "
         & (if External_Client_Traversal_Observed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""boundary_status"": "
         & Q (Status_Name (Boundary_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""status"": "
         & Q
             (if External_Client_Traversal_Observed
              then "success"
              else "blocked_transport_unavailable"));
      Ada.Text_IO.Put_Line ("}");
   exception
      when E : others =>
         Ada.Text_IO.Put_Line ("{");
         Ada.Text_IO.Put_Line
           ("  ""schema"": ""org.a11y.native_client_uia_external_client.v1"",");
         Ada.Text_IO.Put_Line ("  ""platform"": ""Windows"",");
         Ada.Text_IO.Put_Line ("  ""native_api"": ""UI Automation"",");
         Ada.Text_IO.Put_Line
           ("  ""native_bridge_compiled_for_windows"": "
            & (if A11y.Windows_Backend.UIA_Native_Bridge.Bridge_Is_Windows /= 0
               then "true" else "false")
            & ",");
         Ada.Text_IO.Put_Line
           ("  ""native_bridge_stub_runtime"": "
            & (if A11y.Windows_Backend.UIA_Native_Bridge.Bridge_Is_Windows /= 0
               then "false" else "true")
            & ",");
         Ada.Text_IO.Put_Line ("  ""client_process"": ""native_client_uia"",");
         Ada.Text_IO.Put_Line
           ("  ""probe"": ""external_uia_client_traverses_com_fragment_root"",");
         Ada.Text_IO.Put_Line
           ("  ""required_native_boundary"": ""live_uia_com_provider_export"",");
         Ada.Text_IO.Put_Line
           ("  ""next_required_evidence"": ""external_uia_client_traverses_com_fragment_root"",");
         Ada.Text_IO.Put_Line
         ("  ""transport_status"": ""blocked_transport_unavailable"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_client_runtime_probed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_client_runtime_available"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_client_coinitialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_client_automation_created"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_client_root_element_obtained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_client_root_name_obtained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_client_coinitialize_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_client_cocreate_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_client_get_root_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_client_get_name_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_host_window_probed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_host_window_handshake_available"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_host_window_class_registered"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_host_window_created"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_host_window_wm_getobject_sent"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_host_window_root_object_id_matched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_host_window_return_provider_called"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_host_window_null_provider_returned_zero"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_host_window_destroyed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_host_window_register_error"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_host_window_create_error"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_host_window_return_provider_lresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_minimal_provider_probed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_minimal_provider_host_window_available"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_minimal_provider_coinitialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_minimal_provider_window_class_registered"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_minimal_provider_window_created"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_minimal_provider_created"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_minimal_provider_wm_getobject_sent"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_minimal_provider_root_object_id_matched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_minimal_provider_return_provider_called"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_minimal_provider_return_provider_nonzero"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_minimal_provider_query_interface_called"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_minimal_provider_add_ref_called"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_minimal_provider_release_called"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_minimal_provider_options_called"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_minimal_provider_element_from_handle_called"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_minimal_provider_element_from_handle_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_minimal_provider_window_destroyed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_minimal_provider_final_ref_count"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_minimal_provider_coinitialize_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_minimal_provider_register_error"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_minimal_provider_create_error"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_minimal_provider_return_provider_lresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_minimal_provider_cocreate_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_minimal_provider_element_from_handle_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_probed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_host_window_available"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_coinitialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_window_created"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_created"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_wm_getobject_sent"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_root_object_id_matched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_return_provider_called"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_return_provider_nonzero"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_query_interface_called"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_add_ref_called"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_release_called"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_options_called"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_options_callback_called"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_options_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_pattern_provider_called"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_pattern_provider_callback_called"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_pattern_provider_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_pattern_provider_support_callback_called"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_pattern_provider_support_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_pattern_provider_returned_invoke"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_pattern_provider_returned_toggle"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_pattern_provider_returned_expand_collapse"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_pattern_provider_returned_scroll_item"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_pattern_provider_returned_selection_item"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_pattern_provider_returned_range_value"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_pattern_provider_returned_window"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_invoke_provider_invoke_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_toggle_provider_toggle_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_toggle_provider_get_state_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_toggle_provider_state"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_expand_collapse_provider_expand_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_expand_collapse_provider_collapse_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_expand_collapse_provider_get_state_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_expand_collapse_provider_state"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_scroll_item_provider_scroll_into_view_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_selection_item_provider_select_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_selection_item_provider_add_to_selection_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_selection_item_provider_remove_from_selection_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_selection_item_provider_get_is_selected_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_selection_item_provider_is_selected"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_selection_item_provider_get_selection_container_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_selection_item_provider_returned_selection_container"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_range_value_provider_set_value_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_range_value_provider_get_value_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_range_value_provider_get_is_read_only_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_range_value_provider_get_maximum_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_range_value_provider_get_minimum_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_range_value_provider_get_large_change_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_range_value_provider_get_small_change_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_window_provider_close_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_window_provider_get_can_maximize_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_window_provider_get_can_minimize_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_window_provider_get_is_modal_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_window_provider_get_visual_state_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_window_provider_get_interaction_state_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_advise_events_advise_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_advise_events_unadvise_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_property_value_called"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_property_value_callback_called"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_property_value_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_host_raw_element_provider_called"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_host_raw_element_provider_callback_called"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_host_raw_element_provider_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_host_raw_element_provider_returned_host"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_fragment_query_interface_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_fragment_navigate_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_fragment_runtime_id_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_fragment_bounding_rectangle_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_fragment_embedded_roots_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_fragment_set_focus_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_fragment_root_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_fragment_root_query_interface_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_root_from_point_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_root_from_point_returned_fragment"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_root_get_focus_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_root_get_focus_returned_fragment"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_full_frame_callback_called"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_full_frame_callback_succeeded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_window_destroyed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_options_callback_session"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_options_callback_provider"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_options_callback_method"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_options_callback_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_pattern_callback_session"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_pattern_callback_provider"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_pattern_callback_method"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_pattern_callback_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_property_callback_session"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_property_callback_provider"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_property_callback_method"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_property_callback_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_host_callback_session"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_host_callback_provider"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_host_callback_method"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_host_callback_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_full_frame_simple_count"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_full_frame_fragment_count"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_full_frame_root_count"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_full_frame_advise_events_count"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_full_frame_session"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_full_frame_provider"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_full_frame_object_token"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_full_frame_interface"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_full_frame_method"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_full_frame_direction"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_full_frame_point_x"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_full_frame_point_y"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_full_frame_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_final_ref_count"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_coinitialize_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_return_provider_lresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_options_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_property_value_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_pattern_provider_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_invoke_provider_invoke_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_toggle_provider_toggle_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_host_raw_element_provider_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_fragment_navigate_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_fragment_runtime_id_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_fragment_bounding_rectangle_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_fragment_embedded_roots_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_fragment_set_focus_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_fragment_root_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_root_from_point_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""windows_uia_callback_provider_root_get_focus_hresult"": ""0"",");
         Ada.Text_IO.Put_Line
           ("  ""failure_stage"": ""exception"",");
         Ada.Text_IO.Put_Line
           ("  ""exception_name"": "
            & Q (Ada.Exceptions.Exception_Name (E))
            & ",");
         Ada.Text_IO.Put_Line
           ("  ""provider_export_observed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fragment_interface_queried"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fragment_navigate_dispatched"": false,");
         Ada.Text_IO.Put_Line
         ("  ""fragment_runtime_id_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fragment_last_child_frame_dispatched"": false,");
         Ada.Text_IO.Put_Line ("  ""fragment_root_dispatched"": false,");
         Ada.Text_IO.Put_Line ("  ""root_interface_queried"": false,");
         Ada.Text_IO.Put_Line ("  ""root_point_dispatched"": false,");
         Ada.Text_IO.Put_Line ("  ""root_focus_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""pattern_provider_frame_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""bounding_rectangle_frame_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""simple_property_frame_dispatched"": false,");
         Ada.Text_IO.Put_Line
         ("  ""fragment_action_frame_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fragment_set_focus_payload_preserved"": false,");
         Ada.Text_IO.Put_Line
           ("  ""released_interface_rejected"": false,");
         Ada.Text_IO.Put_Line ("  ""object_token_released"": false,");
         Ada.Text_IO.Put_Line
           ("  ""released_object_token_rejected"": false,");
         Ada.Text_IO.Put_Line
           ("  ""com_live_chain_observed"": false,");
         Ada.Text_IO.Put_Line ("  ""metadata_name_preserved"": false,");
         Ada.Text_IO.Put_Line
           ("  ""metadata_identifier_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""metadata_help_preserved"": false,");
         Ada.Text_IO.Put_Line
           ("  ""metadata_placeholder_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""metadata_detail_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""metadata_group_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""protected_value_suppressed"": false,");
         Ada.Text_IO.Put_Line ("  ""privacy_boundary_observed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""internal_native_export_chain_ready"": false,");
         Ada.Text_IO.Put_Line
           ("  ""external_client_traversal_observed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""semantic_state_mutated"": false,");
         Ada.Text_IO.Put_Line
           ("  ""native_conformance_ready"": false,");
         Ada.Text_IO.Put_Line
           ("  ""boundary_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line
           ("  ""status"": ""blocked_transport_unavailable""");
         Ada.Text_IO.Put_Line ("}");
   end Emit_External_Client_Probe;
begin
   if Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--probe-runtime"
   then
      Emit_Runtime_Probe;
   elsif Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--probe-fixture-root"
   then
      Emit_Fixture_Root_Probe;
   elsif Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--probe-registered-boundary"
   then
      Emit_Registered_Boundary_Probe;
   elsif Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--probe-external-client"
   then
      Emit_External_Client_Probe;
   else
      Ada.Text_IO.Put
        (A11y_Native_Client_Reports.JSON
           (A11y_Native_Client_Reports.Windows_UIA));
   end if;
end Native_Client_UIA;
