with Ada.Calendar;
with Ada.Command_Line;
with Ada.Directories;
with Ada.Exceptions;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Strings.Wide_Wide_Unbounded;
with Ada.Text_IO;
with Interfaces.C;

with A11y.Actions;
with A11y.Capabilities;
with A11y.Dispatchers;
with A11y.Documents;
with A11y.Events;
with A11y.MacOS_Backend.NSAccessibility_ABI_Surface;
with A11y.MacOS_Backend.NSAccessibility_Actions;
with A11y.MacOS_Backend.NSAccessibility_Bridge_Audit;
with A11y.MacOS_Backend.NSAccessibility_Document;
with A11y.MacOS_Backend.NSAccessibility_Element_Registry;
with A11y.MacOS_Backend.NSAccessibility_Elements;
with A11y.MacOS_Backend.NSAccessibility_Events;
with A11y.MacOS_Backend.NSAccessibility_Image;
with A11y.MacOS_Backend.NSAccessibility_Live_Regions;
with A11y.MacOS_Backend.NSAccessibility_Native_Callbacks;
with A11y.MacOS_Backend.NSAccessibility_Native_Bridge;
with A11y.MacOS_Backend.NSAccessibility_Properties;
with A11y.MacOS_Backend.NSAccessibility_Provider_Boundary;
with A11y.MacOS_Backend.NSAccessibility_Public_Roots;
with A11y.MacOS_Backend.NSAccessibility_Request_Router;
with A11y.MacOS_Backend.NSAccessibility_Selection;
with A11y.MacOS_Backend.NSAccessibility_Surfaces;
with A11y.MacOS_Backend.NSAccessibility_Table;
with A11y.MacOS_Backend.NSAccessibility_Text;
with A11y.MacOS_Backend.NSAccessibility_Values;
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
with A11y.MacOS_Backend.NSAccessibility_Mappings;

with A11y_Native_Client_Reports;
with A11y_Fixture_Application;
with A11y_NSAX_Native_Runtime_Probes;
with A11y_Test_Fixtures;

procedure Native_Client_NSAX is
   use Ada.Strings.Unbounded;
   use Ada.Strings.Wide_Wide_Unbounded;
   use type A11y.Results.Status_Code;
   use type A11y.Actions.Action_Id;
   use type A11y.Geometry.Length;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Text.Text_Edit_Kind;
   use type A11y.MacOS_Backend.NSAccessibility_Selection
     .Selection_Request_Kind;
   use type A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
     .Boundary_Reply_Kind;
   use type A11y.MacOS_Backend.NSAccessibility_Element_Registry.Element_Id;
   use type A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
     .Native_Status;
   use type A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
     .Native_Method_Family;
   use type A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
     .Native_Request_Kind;
   use type A11y.MacOS_Backend.NSAccessibility_ABI_Surface.NSAX_Selector;
   use type A11y.MacOS_Backend.NSAccessibility_Bridge_Audit
     .Ownership_Rule;
   use type A11y.MacOS_Backend.NSAccessibility_Bridge_Audit.Thread_Rule;
   use type A11y.MacOS_Backend.NSAccessibility_Bridge_Audit
     .Exception_Rule;
   use type A11y.MacOS_Backend.NSAccessibility_Bridge_Audit
     .Lifetime_Rule;
   use type A11y.MacOS_Backend.NSAccessibility_Mappings
     .NSAX_Relation_Attribute;
   use type A11y.MacOS_Backend.NSAccessibility_Properties.Reply_Kind;
   use type A11y.MacOS_Backend.NSAccessibility_Request_Router
     .Routed_Reply_Kind;

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
      type Snapshot_Access is access all
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Snapshot_Bundle;
      type Native_Runtime_Access is access all
        A11y.Native_Runtimes.Native_Runtime;
      type Runtime_Lifecycle_Report_Access is access all
        A11y.Native_Runtimes.Runtime_Lifecycle_Report;
      type Element_Object_Access is access all
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Object;
      type Element_Call_Context_Access is access all
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Context;
      type Element_Call_Snapshot_Access is access all
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Snapshot;
      type Boundary_Request_Access is access all
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Request;
      type Boundary_Reply_Access is access all
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Reply;
      type Element_Snapshot_Access is access all
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Snapshot;
      type Element_Registry_Access is access all
        A11y.MacOS_Backend.NSAccessibility_Element_Registry.Element_Registry;
      type Element_Record_Snapshot_Access is access all
        A11y.MacOS_Backend.NSAccessibility_Element_Registry
          .Element_Record_Snapshot;
      type Registry_Mutation_Report_Access is access all
        A11y.MacOS_Backend.NSAccessibility_Element_Registry
          .Registry_Mutation_Report;

      Root : constant A11y.Node_Ids.Node_Id :=
        A11y_Test_Fixtures.Application_Id;
      Runtime_Ref : constant Native_Runtime_Access := new
        A11y.Native_Runtimes.Native_Runtime;
      Runtime : A11y.Native_Runtimes.Native_Runtime renames Runtime_Ref.all;
      Initialize_Report_Ref : constant Runtime_Lifecycle_Report_Access := new
        A11y.Native_Runtimes.Runtime_Lifecycle_Report;
      Initialize_Report : A11y.Native_Runtimes.Runtime_Lifecycle_Report
        renames Initialize_Report_Ref.all;
      Start_Report_Ref : constant Runtime_Lifecycle_Report_Access := new
        A11y.Native_Runtimes.Runtime_Lifecycle_Report;
      Start_Report : A11y.Native_Runtimes.Runtime_Lifecycle_Report
        renames Start_Report_Ref.all;
      Element_Ref : constant Element_Object_Access := new
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Object;
      Element :
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Object
        renames Element_Ref.all;
      Context_Ref : constant Element_Call_Context_Access := new
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Context;
      Context :
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Context
        renames Context_Ref.all;
      Call_Snapshot_Ref : constant Element_Call_Snapshot_Access := new
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Snapshot;
      Call_Snapshot :
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Snapshot
        renames Call_Snapshot_Ref.all;
      Snapshots :
        constant Snapshot_Access := new
          A11y.MacOS_Backend.NSAccessibility_Request_Router.Snapshot_Bundle;
      Boundary_Request_Ref : constant Boundary_Request_Access := new
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Request;
      Boundary_Request :
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Request
        renames Boundary_Request_Ref.all;
      Boundary_Reply_Ref : constant Boundary_Reply_Access := new
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Reply;
      Boundary_Reply :
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Reply
        renames Boundary_Reply_Ref.all;
      Result : A11y.Results.Result;
      Native_Component : Natural := 0;
      Root_Native_Component : Natural := 0;
      Started : Boolean := False;
      Element_Created : Boolean := False;
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
      Element_After_Call_Ref : constant Element_Snapshot_Access := new
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Snapshot;
      Element_After_Call :
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Snapshot
        renames Element_After_Call_Ref.all;
      Registry_Ref : constant Element_Registry_Access := new
        A11y.MacOS_Backend.NSAccessibility_Element_Registry.Element_Registry;
      Registry :
        A11y.MacOS_Backend.NSAccessibility_Element_Registry.Element_Registry
        renames Registry_Ref.all;
      Registry_Id :
        A11y.MacOS_Backend.NSAccessibility_Element_Registry.Element_Id :=
          A11y.MacOS_Backend.NSAccessibility_Element_Registry.No_Element;
      Child_Registry_Id :
        A11y.MacOS_Backend.NSAccessibility_Element_Registry.Element_Id :=
          A11y.MacOS_Backend.NSAccessibility_Element_Registry.No_Element;
      Registry_View_Ref : constant Element_Record_Snapshot_Access := new
        A11y.MacOS_Backend.NSAccessibility_Element_Registry
          .Element_Record_Snapshot;
      Registry_View :
        A11y.MacOS_Backend.NSAccessibility_Element_Registry
          .Element_Record_Snapshot renames Registry_View_Ref.all;
      Registry_Report_Ref : constant Registry_Mutation_Report_Access := new
        A11y.MacOS_Backend.NSAccessibility_Element_Registry
          .Registry_Mutation_Report;
      Registry_Report :
        A11y.MacOS_Backend.NSAccessibility_Element_Registry
          .Registry_Mutation_Report renames Registry_Report_Ref.all;
      Registry_Element_Created : Boolean := False;
      Registry_Drained_Reset : Boolean := False;
      Registry_Node_Lookup_Rejected : Boolean := False;
      Registry_Stale_Id_Rejected : Boolean := False;
      Registry_Child_Element_Created : Boolean := False;
      Registry_Child_Stale_Id_Rejected : Boolean := False;

      function Probe_Completed return Boolean is
        (Started
         and then Element_Created
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
         and then Registry_Element_Created
         and then Registry_Child_Element_Created
         and then Registry_Drained_Reset
         and then Registry_Node_Lookup_Rejected
         and then Registry_Stale_Id_Rejected
         and then Registry_Child_Stale_Id_Rejected
         and then Boundary_Status = A11y.Results.Success);

      function Failure_Stage return String is
      begin
         if not Started then
            return "runtime_start";
         elsif not Element_Created then
            return "element_creation";
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
         elsif not Registry_Element_Created then
            return "registry_element_creation";
         elsif not Registry_Child_Element_Created then
            return "registry_child_element_creation";
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
      A11y.Native_Runtimes.Initialize_With_Report
        (Runtime, Initialize_Report, Result);
      if A11y.Results.Succeeded (Result) then
         A11y.Native_Runtimes.Start_With_Report
           (Runtime, Start_Report, Result);
      end if;
      Started := A11y.Results.Succeeded (Result);

      if Started then
         A11y.MacOS_Backend.NSAccessibility_Elements.Initialize
           (Element,
            A11y.Native_Runtimes.Session (Runtime),
            Root,
            Root,
            Result);
         Element_Created := A11y.Results.Succeeded (Result);
      end if;

      if Element_Created then
         A11y.MacOS_Backend.NSAccessibility_Elements.Begin_Native_Call
           (Element,
            Context,
            Result);
         Call_Snapshot :=
           A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Context);
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
         Snapshots.all.Hierarchy.Session :=
           A11y.Native_Runtimes.Session (Runtime);
         A11y.Trees.Set_Root (Snapshots.all.Properties.Tree, Root, Result);
         A11y.Trees.Set_Root (Snapshots.all.Hierarchy.Tree, Root, Result);
         A11y.Trees.Attach
           (Snapshots.all.Hierarchy.Tree,
            Root,
            A11y_Test_Fixtures.Main_Window_Id,
            Result);
         A11y.Trees.Attach
           (Snapshots.all.Hierarchy.Tree,
            Root,
            A11y_Test_Fixtures.Dialog_Id,
            Result);
         Snapshots.all.Hierarchy.Root := Root;
         Snapshots.all.Hierarchy.Node := Root;
         Snapshots.all.Properties.Role := A11y.Roles.Application;
         Snapshots.all.Properties.Title :=
           A11y.Properties.Present ("Fixture Application");

         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Copy_Attribute_Value;
         Boundary_Request.Attribute :=
           A11y.MacOS_Backend.NSAccessibility_Properties.Title;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Boundary_Status := Boundary_Reply.Status;
         Root_Query_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Status = A11y.Results.Success;

         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Copy_Child_At_Index;
         Boundary_Request.Child_Index := 1;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Root_First_Child_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Hierarchy_Node
           and then Boundary_Reply.Payload.Node =
             A11y_Test_Fixtures.Main_Window_Id;

         Boundary_Request.Child_Index := 2;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Root_Second_Child_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Hierarchy_Node
           and then Boundary_Reply.Payload.Node = A11y_Test_Fixtures.Dialog_Id;

         Snapshots.all.Properties.Id := A11y_Test_Fixtures.Main_Window_Id;
         Snapshots.all.Properties.Root := Root;
         Snapshots.all.Properties.Role := A11y.Roles.Window;
         Snapshots.all.Properties.Title :=
           A11y.Properties.Present ("Main Window");
         Native_Component :=
           A11y.Native_Identity.Runtime_Identifier_Component
             (A11y.Native_Runtimes.Session (Runtime),
              A11y_Test_Fixtures.Main_Window_Id,
              Result);
         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Copy_Attribute_Value;
         Boundary_Request.Attribute :=
           A11y.MacOS_Backend.NSAccessibility_Properties.Title;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Fixture_Child_Query_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router
               .Attribute_String;

         Boundary_Request.Attribute :=
           A11y.MacOS_Backend.NSAccessibility_Properties.Role;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Fixture_Child_Role_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Attribute_Role;

         Snapshots.all.Hierarchy.Node := A11y_Test_Fixtures.Main_Window_Id;
         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Parent;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Fixture_Child_Parent_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Hierarchy_Node
           and then Boundary_Reply.Payload.Node = Root;

         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Element_Id;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Fixture_Child_Native_Identity_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Element_Id
           and then Boundary_Reply.Payload.Id.Root_Component =
             Root_Native_Component
           and then Boundary_Reply.Payload.Id.Node_Component =
             Native_Component;

         Snapshots.all.Hierarchy.Node := A11y_Test_Fixtures.Dialog_Id;
         Boundary_Request.Native_Node_Component :=
           A11y.Native_Identity.Runtime_Identifier_Component
             (A11y.Native_Runtimes.Session (Runtime),
              A11y_Test_Fixtures.Dialog_Id,
              Result);
         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Parent;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Fixture_Second_Child_Parent_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Hierarchy_Node
           and then Boundary_Reply.Payload.Node = Root;

         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Copy_Element_Id;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Fixture_Second_Child_Native_Identity_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Element_Id
           and then Boundary_Reply.Payload.Id.Root_Component =
             Root_Native_Component
           and then Boundary_Reply.Payload.Id.Node_Component =
             Boundary_Request.Native_Node_Component;

         Snapshots.all.Hierarchy.Node := Root;
         Boundary_Request.Native_Node_Component := Root_Native_Component;
         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Children;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Fixture_Sibling_Order_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router
               .Hierarchy_Children
           and then not Boundary_Reply.Payload.Children.Is_Empty
           and then Boundary_Reply.Payload.Children.Last_Index >
             Boundary_Reply.Payload.Children.First_Index
           and then Boundary_Reply.Payload.Children
             (Boundary_Reply.Payload.Children.First_Index) =
               A11y_Test_Fixtures.Main_Window_Id
           and then Boundary_Reply.Payload.Children
             (Boundary_Reply.Payload.Children.First_Index + 1) =
               A11y_Test_Fixtures.Dialog_Id;
         Root_Child_Count_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router
               .Hierarchy_Children
           and then Natural (Boundary_Reply.Payload.Children.Length) = 2;

         A11y.MacOS_Backend.NSAccessibility_Elements.End_Native_Call
           (Element,
            Context,
            End_Result);
         Element_After_Call :=
           A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Element);
         Native_Call_Completed :=
           A11y.Results.Succeeded (End_Result)
           and then not
             A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot
               (Context).Active
           and then Element_After_Call.Active_Calls = 0
           and then Element_After_Call.Call_Generation >
             Call_Snapshot.Native_Call_Generation;
         Native_Call_Drained :=
           Native_Call_Completed
           and then A11y.MacOS_Backend.NSAccessibility_Elements.Drained
             (Element);
      end if;

      if Started then
         A11y.MacOS_Backend.NSAccessibility_Element_Registry.Ensure_Element
           (Registry,
            A11y.Native_Runtimes.Session (Runtime),
            Root,
            Root,
            Registry_Id,
            Result);
         Registry_Element_Created := A11y.Results.Succeeded (Result);
      end if;

      if Registry_Element_Created then
         A11y.MacOS_Backend.NSAccessibility_Element_Registry.Ensure_Element
           (Registry,
            A11y.Native_Runtimes.Session (Runtime),
            Root,
            A11y_Test_Fixtures.Main_Window_Id,
            Child_Registry_Id,
            Result);
         Registry_Child_Element_Created := A11y.Results.Succeeded (Result);
      end if;

      if Registry_Child_Element_Created then
         A11y.MacOS_Backend.NSAccessibility_Element_Registry.Release
           (Registry,
            A11y.Native_Runtimes.Session (Runtime),
            Child_Registry_Id,
            Result);
         if A11y.Results.Succeeded (Result) then
            A11y.MacOS_Backend.NSAccessibility_Element_Registry.Release
              (Registry,
               A11y.Native_Runtimes.Session (Runtime),
               Registry_Id,
               Result);
         end if;
      end if;

      if Registry_Child_Element_Created and then A11y.Results.Succeeded (Result)
      then
         A11y.MacOS_Backend.NSAccessibility_Element_Registry
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
         A11y.MacOS_Backend.NSAccessibility_Element_Registry.Find_Element
           (Registry,
            A11y.Native_Runtimes.Session (Runtime),
            Root,
            Registry_View,
            Result);
         Registry_Node_Lookup_Rejected :=
           Result.Status = A11y.Results.Node_Unavailable
           and then Registry_View.Id =
             A11y.MacOS_Backend.NSAccessibility_Element_Registry.No_Element;

         A11y.MacOS_Backend.NSAccessibility_Element_Registry.Resolve_Element
           (Registry,
            A11y.Native_Runtimes.Session (Runtime),
            Registry_Id,
            Registry_View,
            Result);
         Registry_Stale_Id_Rejected :=
           Result.Status = A11y.Results.Node_Unavailable
           and then Registry_View.Id =
             A11y.MacOS_Backend.NSAccessibility_Element_Registry.No_Element;

         A11y.MacOS_Backend.NSAccessibility_Element_Registry.Resolve_Element
           (Registry,
            A11y.Native_Runtimes.Session (Runtime),
            Child_Registry_Id,
            Registry_View,
            Result);
         Registry_Child_Stale_Id_Rejected :=
           Result.Status = A11y.Results.Node_Unavailable
           and then Registry_View.Id =
             A11y.MacOS_Backend.NSAccessibility_Element_Registry.No_Element;
      end if;

      Ada.Text_IO.Put_Line ("{");
      Ada.Text_IO.Put_Line
        ("  ""schema"": "
         & Q ("org.a11y.native_client_nsax_fixture_root.v1")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_schema"": " & Q (A11y_Fixture_Application.Schema) & ",");
      Ada.Text_IO.Put_Line
        ("  ""client_process"": "
         & Q (A11y_Native_Client_Reports.Client_Process_Name
                (A11y_Native_Client_Reports.MacOS_NSAccessibility))
         & ",");
      Ada.Text_IO.Put_Line ("  ""platform"": ""macOS"",");
      Ada.Text_IO.Put_Line ("  ""native_api"": ""NSAccessibility"",");
      Ada.Text_IO.Put_Line
        ("  ""application_node"": " & Q (A11y.Node_Ids.Image (Root)) & ",");
      Ada.Text_IO.Put_Line
        ("  ""runtime_started"": "
         & (if Started then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_element_created"": "
         & (if Element_Created then "true" else "false")
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
         & Natural'Image (Element_After_Call.Call_Generation)
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_call_active_after_completion"": "
         & Natural'Image (Element_After_Call.Active_Calls)
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
        ("  ""registry_element_created"": "
         & (if Registry_Element_Created then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registry_child_element_created"": "
         & (if Registry_Child_Element_Created then "true" else "false")
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
            & Q ("org.a11y.native_client_nsax_fixture_root.v1")
            & ",");
         Ada.Text_IO.Put_Line
           ("  ""fixture_schema"": " & Q (A11y_Fixture_Application.Schema) & ",");
         Ada.Text_IO.Put_Line ("  ""client_process"": ""native_client_nsax"",");
         Ada.Text_IO.Put_Line ("  ""platform"": ""macOS"",");
         Ada.Text_IO.Put_Line ("  ""native_api"": ""NSAccessibility"",");
         Ada.Text_IO.Put_Line ("  ""application_node"": ""1001"",");
         Ada.Text_IO.Put_Line ("  ""runtime_started"": false,");
         Ada.Text_IO.Put_Line ("  ""native_element_created"": false,");
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
         Ada.Text_IO.Put_Line ("  ""registry_element_created"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registry_child_element_created"": false,");
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
      type Snapshot_Access is access all
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Snapshot_Bundle;

      Root : constant A11y.Node_Ids.Node_Id :=
        A11y_Test_Fixtures.Application_Id;
      Runtime : A11y.Native_Runtimes.Native_Runtime;
      Registry :
        A11y.MacOS_Backend.NSAccessibility_Element_Registry
          .Element_Registry;
      Element :
        A11y.MacOS_Backend.NSAccessibility_Element_Registry.Element_Id :=
          A11y.MacOS_Backend.NSAccessibility_Element_Registry.No_Element;
      Snapshots :
        constant Snapshot_Access := new
          A11y.MacOS_Backend.NSAccessibility_Request_Router.Snapshot_Bundle;
      Boundary_Request :
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
          .Boundary_Request;
      Boundary_Reply :
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Reply;
      Boundary_Report :
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
          .Registered_Native_Request_Report;
      Released_Boundary_Reply :
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Reply;
      Released_Boundary_Report :
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
          .Registered_Native_Request_Report;
      Result : A11y.Results.Result;
      Started : Boolean := False;
      Element_Created : Boolean := False;
      Boundary_Dispatched : Boolean := False;
      Boundary_Report_Complete : Boolean := False;
      Element_Released : Boolean := False;
      Released_Boundary_Rejected : Boolean := False;

      function Probe_Completed return Boolean is
        (Started
         and then Element_Created
         and then Boundary_Dispatched
         and then Boundary_Report_Complete
         and then Element_Released
         and then Released_Boundary_Rejected);

      function Failure_Stage return String is
      begin
         if not Started then
            return "runtime_start";
         elsif not Element_Created then
            return "element_creation";
         elsif not Boundary_Dispatched then
            return "registered_boundary_dispatch";
         elsif not Boundary_Report_Complete then
            return "registered_boundary_report";
         elsif not Element_Released then
            return "registry_element_release";
         elsif not Released_Boundary_Rejected then
            return "released_boundary_rejection";
         else
            return "none";
         end if;
      end Failure_Stage;
   begin
      A11y.Native_Runtimes.Start (Runtime, Result);
      Started := A11y.Results.Succeeded (Result);

      if Started then
         A11y.MacOS_Backend.NSAccessibility_Element_Registry.Ensure_Element
           (Registry,
            A11y.Native_Runtimes.Session (Runtime),
            Root,
            Root,
            Element,
            Result);
         Element_Created := A11y.Results.Succeeded (Result);
      end if;

      if Element_Created then
         Snapshots.all.Properties.Id := Root;
         Snapshots.all.Properties.Root := Root;
         Snapshots.all.Hierarchy.Session :=
           A11y.Native_Runtimes.Session (Runtime);
         Snapshots.all.Properties.Role := A11y.Roles.Button;
         Snapshots.all.Properties.Title := A11y.Properties.Present ("Press");
         Snapshots.all.Actions (A11y.Actions.Press) := True;
         Snapshots.all.Action_Node := Root;
         Snapshots.all.Action_Root := Root;
         A11y.Trees.Set_Root (Snapshots.all.Action_Tree, Root, Result);

         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Perform_Action;
         Boundary_Request.Action := A11y.Actions.Press;
         Boundary_Request.Has_Native_Identity := False;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Registered_Native_Request_With_Report
               (Registry,
                A11y.Native_Runtimes.Session (Runtime),
                Element,
                Boundary_Request,
                Snapshots.all,
                Boundary_Report);

         Boundary_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success;
         Boundary_Report_Complete :=
           Boundary_Report.Method_Family_Supported
           and then Boundary_Report.Method_Family =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Any_Method
           and then Boundary_Report.Request_Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Perform_Action
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

         A11y.MacOS_Backend.NSAccessibility_Element_Registry.Release
           (Registry,
            A11y.Native_Runtimes.Session (Runtime),
            Element,
            Result);
         Element_Released := A11y.Results.Succeeded (Result);

         if Element_Released then
            Boundary_Request.Kind :=
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Copy_Parent;
            Released_Boundary_Reply :=
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Dispatch_Registered_Native_Request_With_Report
                  (Registry,
                   A11y.Native_Runtimes.Session (Runtime),
                   Element,
                   Boundary_Request,
                   Snapshots.all,
                   Released_Boundary_Report);

            Released_Boundary_Rejected :=
              Released_Boundary_Reply.Kind =
                A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                  .Native_Error
              and then Released_Boundary_Reply.Native_Result =
                A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                  .Native_Element_Unavailable
              and then Released_Boundary_Reply.Status =
                A11y.Results.Node_Unavailable
              and then Released_Boundary_Report.Method_Family_Supported
              and then not Released_Boundary_Report.Resolved
              and then not Released_Boundary_Report.Native_Identity_Prepared
              and then not Released_Boundary_Report.Native_Admitted
              and then not Released_Boundary_Report.Native_Completed
              and then Released_Boundary_Report.Reply_Status =
                A11y.Results.Node_Unavailable
              and then Released_Boundary_Report.Final_Status =
                A11y.Results.Node_Unavailable;
         end if;
      end if;

      Ada.Text_IO.Put_Line ("{");
      Ada.Text_IO.Put_Line
        ("  ""schema"": "
         & Q ("org.a11y.native_client_nsax_registered_boundary_probe.v1")
         & ",");
      Ada.Text_IO.Put_Line ("  ""client_process"": ""native_client_nsax"",");
      Ada.Text_IO.Put_Line ("  ""platform"": ""macOS"",");
      Ada.Text_IO.Put_Line ("  ""native_api"": ""NSAccessibility"",");
      Ada.Text_IO.Put_Line
        ("  ""runtime_started"": "
         & (if Started then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registry_element_created"": "
         & (if Element_Created then "true" else "false")
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
        ("  ""registered_boundary_method_family_supported"": "
         & (if Boundary_Report.Method_Family_Supported
            then "true"
            else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_method_family"": "
         & Q
           (A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
              .Native_Method_Family'Image (Boundary_Report.Method_Family))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_request_kind"": "
         & Q
           (A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
              .Native_Request_Kind'Image (Boundary_Report.Request_Kind))
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
        ("  ""registered_boundary_element_released"": "
         & (if Element_Released then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_released_rejected"": "
         & (if Released_Boundary_Rejected then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_released_resolved"": "
         & (if Released_Boundary_Report.Resolved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_released_admitted"": "
         & (if Released_Boundary_Report.Native_Admitted
            then "true"
            else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_released_completed"": "
         & (if Released_Boundary_Report.Native_Completed
            then "true"
            else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_released_reply_status"": "
         & Q (Status_Name (Released_Boundary_Report.Reply_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_released_final_status"": "
         & Q (Status_Name (Released_Boundary_Report.Final_Status))
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
            & Q ("org.a11y.native_client_nsax_registered_boundary_probe.v1")
            & ",");
         Ada.Text_IO.Put_Line ("  ""client_process"": ""native_client_nsax"",");
         Ada.Text_IO.Put_Line ("  ""platform"": ""macOS"",");
         Ada.Text_IO.Put_Line ("  ""native_api"": ""NSAccessibility"",");
         Ada.Text_IO.Put_Line ("  ""runtime_started"": false,");
         Ada.Text_IO.Put_Line ("  ""registry_element_created"": false,");
         Ada.Text_IO.Put_Line ("  ""registered_boundary_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_report_complete"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_method_family_supported"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_method_family"": ""ANY_METHOD"",");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_request_kind"": ""COPY_ATTRIBUTE_VALUE"",");
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
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_element_released"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_released_rejected"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_released_resolved"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_released_admitted"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_released_completed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_released_reply_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_released_final_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line ("  ""probe_status"": ""failed"",");
         Ada.Text_IO.Put_Line ("  ""failure_stage"": ""exception""");
         Ada.Text_IO.Put_Line ("}");
   end Emit_Registered_Boundary_Probe;

   procedure Emit_Runtime_Probe is
      type Snapshot_Access is access all
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Snapshot_Bundle;
      type Native_Runtime_Access is access all
        A11y.Native_Runtimes.Native_Runtime;
      type Prepared_Event_Access is access all
        A11y.Native_Runtimes.Prepared_Event;
      type Event_Emission_Access is access all
        A11y.MacOS_Backend.NSAccessibility_Events.NSAX_Event_Emission;
      type Event_Build_Report_Access is access all
        A11y.MacOS_Backend.NSAccessibility_Events.Event_Build_Report;
      type Element_Object_Access is access all
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Object;
      type Element_Call_Context_Access is access all
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Context;
      type Element_Call_Snapshot_Access is access all
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Snapshot;
      type Boundary_Request_Access is access all
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Request;
      type Boundary_Reply_Access is access all
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Reply;
      type Element_Snapshot_Access is access all
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Snapshot;
      type Element_Export_Access is access all
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Export_Descriptor;

      Root : constant A11y.Node_Ids.Node_Id := A11y.Node_Ids.From_Natural (1);
      Table_Cell : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (771);
      Selection_Item : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (772);
      Runtime_Ref : constant Native_Runtime_Access := new
        A11y.Native_Runtimes.Native_Runtime;
      Runtime : A11y.Native_Runtimes.Native_Runtime renames Runtime_Ref.all;
      Prepared_Ref : constant Prepared_Event_Access := new
        A11y.Native_Runtimes.Prepared_Event;
      Prepared : A11y.Native_Runtimes.Prepared_Event renames Prepared_Ref.all;
      Emission_Ref : constant Event_Emission_Access := new
        A11y.MacOS_Backend.NSAccessibility_Events.NSAX_Event_Emission'
          (Publishable => True,
           others      => <>);
      Emission :
        A11y.MacOS_Backend.NSAccessibility_Events.NSAX_Event_Emission
        renames Emission_Ref.all;
      Report_Ref : constant Event_Build_Report_Access := new
        A11y.MacOS_Backend.NSAccessibility_Events.Event_Build_Report;
      Report :
        A11y.MacOS_Backend.NSAccessibility_Events.Event_Build_Report
        renames Report_Ref.all;
      Result : A11y.Results.Result;
      Event : constant A11y.Events.Event :=
        (Sequence  => 1,
         Timestamp => Ada.Calendar.Clock,
         Source    => Root,
         Kind      => A11y.Events.Focus_Changed,
         Revision  => 1);
      Registry_Ref : constant Element_Object_Access := new
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Object;
      Registry :
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Object
        renames Registry_Ref.all;
      Context_Ref : constant Element_Call_Context_Access := new
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Context;
      Context :
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Context
        renames Context_Ref.all;
      Call_Snapshot_Ref : constant Element_Call_Snapshot_Access := new
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Snapshot;
      Call_Snapshot :
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Snapshot
        renames Call_Snapshot_Ref.all;
      Native_Component : Natural := 0;
      Selection_Component : Natural := 0;
      Snapshots :
        constant Snapshot_Access := new
          A11y.MacOS_Backend.NSAccessibility_Request_Router.Snapshot_Bundle;
      Boundary_Request_Ref : constant Boundary_Request_Access := new
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Request;
      Boundary_Request :
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Request
        renames Boundary_Request_Ref.all;
      Boundary_Reply_Ref : constant Boundary_Reply_Access := new
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Reply;
      Boundary_Reply :
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Reply
        renames Boundary_Reply_Ref.all;
      Started : Boolean := False;
      Prepared_OK : Boolean := False;
      Native_Element_Created : Boolean := False;
      Native_Call_Admitted : Boolean := False;
      Native_Call_Completed : Boolean := False;
      Native_Call_Drained : Boolean := False;
      Main_Thread_Bound : Boolean := False;
      Native_View_Bound : Boolean := False;
      Native_View_Component : Natural := 0;
      Boundary_Query_Dispatched : Boolean := False;
      Selector_Attribute_Value_Prepared : Boolean := False;
      Selector_Unsupported_Rejected : Boolean := False;
      Selector_Main_Thread_Gated : Boolean := False;
      Registered_Method_Family_Mismatch_Rejected : Boolean := False;
      Identifier_Dispatched : Boolean := False;
      Identifier_Payload_Preserved : Boolean := False;
      Attribute_Names_Dispatched : Boolean := False;
      Attribute_Names_Payload_Preserved : Boolean := False;
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
      Element_After_Call_Ref : constant Element_Snapshot_Access := new
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Snapshot;
      Element_After_Call :
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Snapshot
        renames Element_After_Call_Ref.all;
      Element_Export_Ref : constant Element_Export_Access := new
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Export_Descriptor;
      Element_Export :
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Export_Descriptor
        renames Element_Export_Ref.all;
      Selector_Request_Ref : constant Boundary_Request_Access := new
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Request;
      Selector_Request :
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Request
        renames Selector_Request_Ref.all;
      Registered_Elements :
        A11y.MacOS_Backend.NSAccessibility_Element_Registry.Element_Registry;
      Registered_Element :
        A11y.MacOS_Backend.NSAccessibility_Element_Registry.Element_Id :=
          A11y.MacOS_Backend.NSAccessibility_Element_Registry.No_Element;
      Registered_Boundary_Report :
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
          .Registered_Native_Request_Report;
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
         and then Native_Element_Created
         and then Native_Call_Admitted
         and then Native_Call_Completed
         and then Native_Call_Drained
         and then Main_Thread_Bound
         and then Native_View_Bound
         and then Native_View_Component = 23
         and then Boundary_Query_Dispatched
         and then Selector_Attribute_Value_Prepared
         and then Selector_Unsupported_Rejected
         and then Selector_Main_Thread_Gated
         and then Registered_Method_Family_Mismatch_Rejected
         and then Identifier_Dispatched
         and then Identifier_Payload_Preserved
         and then Attribute_Names_Dispatched
         and then Attribute_Names_Payload_Preserved
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
         elsif not Native_Element_Created then
            return "element_creation";
         elsif not Main_Thread_Bound then
            return "main_thread_binding";
         elsif not Native_View_Bound then
            return "native_view_binding";
         elsif not Native_Call_Admitted then
            return "native_call_admission";
         elsif not Boundary_Query_Dispatched then
            return "boundary_query";
         elsif not Selector_Attribute_Value_Prepared then
            return "selector_attribute_value";
         elsif not Selector_Unsupported_Rejected then
            return "selector_unsupported";
         elsif not Selector_Main_Thread_Gated then
            return "selector_main_thread_gate";
         elsif not Registered_Method_Family_Mismatch_Rejected then
            return "registered_method_family_mismatch";
         elsif not Identifier_Dispatched then
            return "identifier";
         elsif not Identifier_Payload_Preserved then
            return "identifier_payload";
         elsif not Attribute_Names_Dispatched then
            return "attribute_names";
         elsif not Attribute_Names_Payload_Preserved then
            return "attribute_names_payload";
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
         A11y.MacOS_Backend.NSAccessibility_Events
           .Build_Prepared_Event_With_Report
             (Prepared, Emission, Report);
      else
         Report.Status := Result.Status;
      end if;

      if Started then
         A11y.MacOS_Backend.NSAccessibility_Elements.Initialize
           (Registry,
            A11y.Native_Runtimes.Session (Runtime),
            Root,
            Root,
            Result);
         Native_Element_Created := A11y.Results.Succeeded (Result);
      end if;

      if Native_Element_Created then
         A11y.MacOS_Backend.NSAccessibility_Elements.Bind_Main_Thread
           (Registry, Result);
         Main_Thread_Bound := A11y.Results.Succeeded (Result);
      end if;

      if Main_Thread_Bound then
         A11y.MacOS_Backend.NSAccessibility_Elements.Bind_Native_View
           (Registry, 23, Result);
         Element_Export :=
           A11y.MacOS_Backend.NSAccessibility_Elements.Export_Descriptor
             (Registry);
         Native_View_Bound :=
           A11y.Results.Succeeded (Result)
           and then Element_Export.Exportable
           and then Element_Export.Main_Thread_Bound
           and then Element_Export.Native_View_Bound
           and then Element_Export.Native_View_Component = 23;
         Native_View_Component := Element_Export.Native_View_Component;
      end if;

      if Native_View_Bound then
         Selector_Request :=
           A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Prepare_Request
             (Element_Export,
              A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                .Accessibility_Attribute_Value,
              Result);
         Selector_Attribute_Value_Prepared :=
           A11y.Results.Succeeded (Result)
           and then
             A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Can_Dispatch
               (Element_Export,
                A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                  .Accessibility_Attribute_Value)
           and then Selector_Request.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Copy_Attribute_Value
           and then Selector_Request.Has_Native_Identity
           and then Selector_Request.Native_Node_Component =
             Element_Export.Native_Node_Component;

         Selector_Request :=
           A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Prepare_Request
             (Element_Export,
              A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                .Accessibility_Is_Attribute_Settable,
              Result);
         Selector_Unsupported_Rejected :=
           Selector_Attribute_Value_Prepared
           and then A11y.Results.Succeeded (Result)
           and then Selector_Request.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Is_Attribute_Settable
           and then Selector_Request.Has_Native_Identity
           and then Selector_Request.Native_Node_Component =
             Element_Export.Native_Node_Component;

         declare
            Ignored_Selector :
              constant
                A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                  .NSAX_Selector :=
                    A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                      .Selector_From_Code (999, Result);
         begin
            Selector_Unsupported_Rejected :=
              Selector_Unsupported_Rejected
              and then Ignored_Selector =
                A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                  .Accessibility_Attribute_Value
              and then Result.Status = A11y.Results.Invalid_Argument;
         end;

         declare
            Unbound_Element :
              A11y.MacOS_Backend.NSAccessibility_Elements.Element_Object;
            Unbound_Export :
              A11y.MacOS_Backend.NSAccessibility_Elements
                .Element_Export_Descriptor;
         begin
            A11y.MacOS_Backend.NSAccessibility_Elements.Initialize
              (Unbound_Element,
               A11y.Native_Runtimes.Session (Runtime),
               Root,
               Root,
               Result);
            Unbound_Export :=
              A11y.MacOS_Backend.NSAccessibility_Elements.Export_Descriptor
                (Unbound_Element);
            Selector_Request :=
              A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Prepare_Request
                (Unbound_Export,
                 A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                   .Accessibility_Perform_Action,
                 Result);
            Selector_Main_Thread_Gated :=
              Selector_Unsupported_Rejected
              and then Result.Status = A11y.Results.Invalid_State
              and then not Selector_Request.Has_Native_Identity;
         end;

         A11y.MacOS_Backend.NSAccessibility_Element_Registry.Ensure_Element
           (Registered_Elements,
            A11y.Native_Runtimes.Session (Runtime),
            Root,
            Root,
            Registered_Element,
            Result);
         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Parent;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Registered_Native_Request_With_Report
               (Registered_Elements,
                A11y.Native_Runtimes.Session (Runtime),
                Registered_Element,
                Boundary_Request,
                Snapshots.all,
                Registered_Boundary_Report,
                Method_Family =>
                  A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                    .Attribute_Method);
         Registered_Method_Family_Mismatch_Rejected :=
           Selector_Main_Thread_Gated
           and then A11y.Results.Succeeded (Result)
           and then Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Nil
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Not_Applicable
           and then Boundary_Reply.Status =
             A11y.Results.Unsupported_Capability
           and then not Registered_Boundary_Report.Method_Family_Supported
           and then not Registered_Boundary_Report.Resolved
           and then not Registered_Boundary_Report.Native_Admitted
           and then not Registered_Boundary_Report.Native_Completed
           and then Registered_Boundary_Report.Reply_Status =
             A11y.Results.Unsupported_Capability
           and then Registered_Boundary_Report.Final_Status =
             A11y.Results.Unsupported_Capability;

         A11y.MacOS_Backend.NSAccessibility_Elements.Begin_Native_Call
           (Registry,
            Context,
            Result,
            Require_Main_Thread => True);
         Call_Snapshot :=
           A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Context);
         Native_Call_Admitted :=
           A11y.Results.Succeeded (Result)
           and then Call_Snapshot.Active
           and then Call_Snapshot.Main_Thread_Bound;
      end if;

      if Native_Call_Admitted then
         Native_Component :=
           A11y.Native_Identity.Runtime_Identifier_Component
             (A11y.Native_Runtimes.Session (Runtime), Root, Result);

         Snapshots.all.Properties.Id := Root;
         Snapshots.all.Properties.Root := Root;
         Snapshots.all.Hierarchy.Session :=
           A11y.Native_Runtimes.Session (Runtime);
         A11y.Trees.Set_Root (Snapshots.all.Properties.Tree, Root, Result);
         Snapshots.all.Properties.Role := A11y.Roles.Button;
         Snapshots.all.Properties.Title :=
           A11y.Properties.Present ("Probe Button");
         Snapshots.all.Properties.Identifier :=
           A11y.Properties.Present ("probe-button");

         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Copy_Attribute_Value;
         Boundary_Request.Attribute :=
           A11y.MacOS_Backend.NSAccessibility_Properties.Title;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Boundary_Status := Boundary_Reply.Status;
         Boundary_Query_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Status = A11y.Results.Success;

         Boundary_Request.Attribute :=
           A11y.MacOS_Backend.NSAccessibility_Properties.Identifier;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Identifier_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router
               .Attribute_String;
         Identifier_Payload_Preserved :=
           Identifier_Dispatched
           and then To_String (Boundary_Reply.Payload.Text) = "probe-button";

         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Copy_Attribute_Names;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Attribute_Names_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Attribute_Set;
         Attribute_Names_Payload_Preserved :=
           Attribute_Names_Dispatched
           and then Boundary_Reply.Payload.Attributes
             (A11y.MacOS_Backend.NSAccessibility_Properties.Role)
           and then Boundary_Reply.Payload.Attributes
             (A11y.MacOS_Backend.NSAccessibility_Properties.Title)
           and then Boundary_Reply.Payload.Attributes
             (A11y.MacOS_Backend.NSAccessibility_Properties.Frame)
           and then Boundary_Reply.Payload.Attributes
             (A11y.MacOS_Backend.NSAccessibility_Properties.Identifier);

         Snapshots.all.Action_Node := Root;
         Snapshots.all.Action_Root := Root;
         Snapshots.all.Actions :=
           A11y.Actions.With_Action
             (A11y.Actions.With_Action
                (A11y.Actions.Empty_Action_Set, A11y.Actions.Press),
              A11y.Actions.Expand);
         A11y.Trees.Set_Root (Snapshots.all.Action_Tree, Root, Result);

         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Copy_Action_Names;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Action_Discovery_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Action_Set;
         Action_Payload_Preserved :=
           Action_Discovery_Dispatched
           and then Boundary_Reply.Payload.Actions
             (A11y.MacOS_Backend.NSAccessibility_Actions.Press)
           and then Boundary_Reply.Payload.Actions
             (A11y.MacOS_Backend.NSAccessibility_Actions.Expand);

         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Perform_Action;
         Boundary_Request.Action := A11y.Actions.Expand;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Action_Request_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Action_Request;
         Action_Request_Payload_Preserved :=
           Action_Request_Dispatched
           and then Boundary_Reply.Payload.Requested_Action =
             A11y.Actions.Expand;

         Snapshots.all.Text.Id := Root;
         Snapshots.all.Text.Root := Root;
         Snapshots.all.Text.Content :=
           To_Unbounded_Wide_Wide_String ("Probe Text");

         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Text;
         Boundary_Request.Text :=
           A11y.MacOS_Backend.NSAccessibility_Text.Text_Range;
         Boundary_Request.Index := 1;
         Boundary_Request.Count := 5;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Text_Range_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Text_Wide_Text;
         Text_Range_Payload_Preserved :=
           Text_Range_Dispatched
           and then To_Wide_Wide_String (Boundary_Reply.Payload.Wide_Text) =
             "Probe";

         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Edit_Text;
         Boundary_Request.Text_Edit := A11y.Text.Insert_Text;
         Boundary_Request.Index := 2;
         Boundary_Request.Count := 0;
         Boundary_Request.Replacement :=
           To_Unbounded_Wide_Wide_String ("X");
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Text_Edit_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Text_Edit_Request;
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
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Edit_Text;
         Boundary_Request.Text_Edit := A11y.Text.Delete_Text;
         Boundary_Request.Index := 3;
         Boundary_Request.Count := 2;
         Boundary_Request.Replacement :=
           Null_Unbounded_Wide_Wide_String;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Text_Delete_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Text_Edit_Request;
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
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Edit_Text;
         Boundary_Request.Text_Edit := A11y.Text.Replace_Text;
         Boundary_Request.Index := 4;
         Boundary_Request.Count := 3;
         Boundary_Request.Replacement :=
           To_Unbounded_Wide_Wide_String ("XYZ");
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Text_Replace_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Text_Edit_Request;
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
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Edit_Text;
         Boundary_Request.Text_Edit := A11y.Text.Set_Text;
         Boundary_Request.Index := 1;
         Boundary_Request.Count := 0;
         Boundary_Request.Replacement :=
           To_Unbounded_Wide_Wide_String ("Reset");
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Text_Set_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Text_Edit_Request;
         Text_Set_Payload_Preserved :=
           Text_Set_Dispatched
           and then Boundary_Reply.Payload.Requested_Edit.Kind =
             A11y.Text.Set_Text
           and then A11y.Text.Length
             (Boundary_Reply.Payload.Requested_Edit.Span) = 0
           and then To_Wide_Wide_String
             (Boundary_Reply.Payload.Requested_Edit.Text) = "Reset";

         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Copy_Attribute_Value;
         Boundary_Request.Attribute :=
           A11y.MacOS_Backend.NSAccessibility_Properties.Title;
         Boundary_Request.Has_Native_Identity := False;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Missing_Identity_Rejected :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Invalid_Argument
           and then Boundary_Reply.Status = A11y.Results.Invalid_Argument;

         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component :=
           A11y.Native_Identity.Runtime_Identifier_Component
             (A11y.Native_Runtimes.Session (Runtime), Table_Cell, Result);
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Mismatched_Identity_Rejected :=
           A11y.Results.Succeeded (Result)
           and then Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Element_Unavailable
           and then Boundary_Reply.Status = A11y.Results.Node_Unavailable;

         Boundary_Request.Native_Node_Component := 0;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Malformed_Identity_Rejected :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Element_Unavailable
           and then Boundary_Reply.Status = A11y.Results.Node_Unavailable;

         A11y.Resource_Limits.Set_Limit
           (Snapshots.all.Limits,
            A11y.Resource_Limits.Native_String_Size,
            1,
            Result);
         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Edit_Text;
         Boundary_Request.Text_Edit := A11y.Text.Insert_Text;
         Boundary_Request.Index := 1;
         Boundary_Request.Count := 0;
         Boundary_Request.Replacement := To_Unbounded_Wide_Wide_String ("XX");
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Text_Payload_Limit_Rejected :=
           A11y.Results.Succeeded (Result)
           and then Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Out_Of_Resources
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
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Table;
         Boundary_Request.Table :=
           A11y.MacOS_Backend.NSAccessibility_Table.Current_Cell;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Table_Current_Cell_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Table_Node;
         Table_Current_Cell_Payload_Preserved :=
           Table_Current_Cell_Dispatched
           and then Boundary_Reply.Payload.Node = Table_Cell;

         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Table;
         Boundary_Request.Table :=
           A11y.MacOS_Backend.NSAccessibility_Table.Sort_Order;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Table_Sort_Order_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Table_UInt32;
         Table_Sort_Order_Payload_Preserved :=
           Table_Sort_Order_Dispatched
           and then Boundary_Reply.Payload.UInt32 =
             A11y.Tables.Sort_Order'Pos (A11y.Tables.Descending);

         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Table;
         Boundary_Request.Table :=
           A11y.MacOS_Backend.NSAccessibility_Table.Sort_Key;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Table_Sort_Key_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Table_Node;
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
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Value;
         Boundary_Request.Value :=
           A11y.MacOS_Backend.NSAccessibility_Values.Value;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Value_Current_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Value_Float;
         Value_Current_Payload_Preserved :=
           Value_Current_Dispatched
           and then Boundary_Reply.Payload.Float_Item = 5.0;

         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Set_Value;
         Boundary_Request.Requested_Value := A11y.Values.Floating (6.0);
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Value_Set_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Value_Set_Request;
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
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Selection;
         Boundary_Request.Selection :=
           A11y.MacOS_Backend.NSAccessibility_Selection.Selected_Count;
         Boundary_Request.Index := 1;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Selection_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Selection_Count_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Selection_UInt32;
         Selection_Count_Payload_Preserved :=
           Selection_Count_Dispatched
           and then Boundary_Reply.Payload.UInt32 = 1;

         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Selection;
         Boundary_Request.Selection :=
           A11y.MacOS_Backend.NSAccessibility_Selection.Selected_Item;
         Boundary_Request.Index := 1;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Selection_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Selection_Item_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Selection_Node;
         Selection_Item_Payload_Preserved :=
           Selection_Item_Dispatched
           and then Boundary_Reply.Payload.Node = Selection_Item;

         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Set_Selection;
         Boundary_Request.Selection_Request :=
           A11y.MacOS_Backend.NSAccessibility_Selection.Toggle_Item;
         Boundary_Request.Selection_Target := Selection_Item;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Selection_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Selection_Request_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router
               .Selection_Request_Reply;
         Selection_Request_Payload_Preserved :=
           Selection_Request_Dispatched
           and then Boundary_Reply.Payload.Selection_Target = Selection_Item
           and then Boundary_Reply.Payload.Selection_Request =
             A11y.MacOS_Backend.NSAccessibility_Selection.Toggle_Item;

         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Set_Selection;
         Boundary_Request.Selection_Request :=
           A11y.MacOS_Backend.NSAccessibility_Selection.Select_All;
         Boundary_Request.Selection_Target := A11y.Node_Ids.No_Node;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Selection_Select_All_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router
               .Selection_Request_Reply;
         Selection_Select_All_Payload_Preserved :=
           Selection_Select_All_Dispatched
           and then Boundary_Reply.Payload.Selection_Target =
             A11y.Node_Ids.No_Node
           and then Boundary_Reply.Payload.Selection_Request =
             A11y.MacOS_Backend.NSAccessibility_Selection.Select_All;

         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Set_Selection;
         Boundary_Request.Selection_Request :=
           A11y.MacOS_Backend.NSAccessibility_Selection.Clear_Selection;
         Boundary_Request.Selection_Target := A11y.Node_Ids.No_Node;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Selection_Clear_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router
               .Selection_Request_Reply;
         Selection_Clear_Payload_Preserved :=
           Selection_Clear_Dispatched
           and then Boundary_Reply.Payload.Selection_Target =
             A11y.Node_Ids.No_Node
           and then Boundary_Reply.Payload.Selection_Request =
             A11y.MacOS_Backend.NSAccessibility_Selection.Clear_Selection;

         Snapshots.all.Relation_Source := Root;
         A11y.Relations.Add
           (Snapshots.all.Relations,
            Root,
            A11y.Relations.Labelled_By,
            Selection_Item,
            Result);
         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Copy_Relation_Targets;
         Boundary_Request.Relation := A11y.Relations.Labelled_By;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Relation_Target_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router
               .Relation_Targets;
         Relation_Target_Payload_Preserved :=
           Relation_Target_Dispatched
           and then Boundary_Reply.Payload.Relation_Attribute =
             A11y.MacOS_Backend.NSAccessibility_Mappings.Title_UI_Element;

         Snapshots.all.Document.Id := Root;
         Snapshots.all.Document.Root := Root;
         Snapshots.all.Document.Metadata.Role := A11y.Documents.Heading;
         Snapshots.all.Document.Metadata.Heading_Level := 2;
         Snapshots.all.Document.Metadata.Title :=
           To_Unbounded_String ("Probe Document");

         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Copy_Document;
         Boundary_Request.Document :=
           A11y.MacOS_Backend.NSAccessibility_Document.Title;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Document_Title_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Document_String;
         Document_Title_Payload_Preserved :=
           Document_Title_Dispatched
           and then To_String (Boundary_Reply.Payload.Text) = "Probe Document";

         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Copy_Document;
         Boundary_Request.Document :=
           A11y.MacOS_Backend.NSAccessibility_Document.Heading_Level;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Document_Heading_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Document_UInt32;
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
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Image;
         Boundary_Request.Image :=
           A11y.MacOS_Backend.NSAccessibility_Image.Description;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Image_Description_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Image_String;
         Image_Description_Payload_Preserved :=
           Image_Description_Dispatched
           and then To_String (Boundary_Reply.Payload.Text) =
             "Probe image alternative";

         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Image;
         Boundary_Request.Image :=
           A11y.MacOS_Backend.NSAccessibility_Image.Intrinsic_Size;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Image_Size_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Image_Size;
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
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Copy_Live_Region;
         Boundary_Request.Live_Region :=
           A11y.MacOS_Backend.NSAccessibility_Live_Regions.Setting_Name;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Live_Setting_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Live_String;
         Live_Setting_Payload_Preserved :=
           Live_Setting_Dispatched
           and then To_String (Boundary_Reply.Payload.Text) = "assertive";

         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Copy_Live_Region;
         Boundary_Request.Live_Region :=
           A11y.MacOS_Backend.NSAccessibility_Live_Regions.Is_Atomic;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Live_Atomic_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Live_Boolean;
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
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Surface;
         Boundary_Request.Surface :=
           A11y.MacOS_Backend.NSAccessibility_Surfaces.Kind_Name;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Surface_Kind_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Surface_String;
         Surface_Kind_Payload_Preserved :=
           Surface_Kind_Dispatched
           and then To_String (Boundary_Reply.Payload.Text) = "dialog";

         Boundary_Request.Kind :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Surface;
         Boundary_Request.Surface :=
           A11y.MacOS_Backend.NSAccessibility_Surfaces.Is_Active;
         Boundary_Request.Has_Native_Identity := True;
         Boundary_Request.Native_Node_Component := Native_Component;
         Boundary_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Dispatch_Native_Request (Boundary_Request, Snapshots.all);
         Surface_Active_Dispatched :=
           Boundary_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
           and then Boundary_Reply.Native_Result =
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Success
           and then Boundary_Reply.Status = A11y.Results.Success
           and then Boundary_Reply.Routed =
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Surface_Boolean;
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

         A11y.MacOS_Backend.NSAccessibility_Elements.End_Native_Call
           (Registry,
            Context,
            End_Result);
         Element_After_Call :=
           A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Registry);
         Native_Call_Completed :=
           A11y.Results.Succeeded (End_Result)
           and then not
             A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot
               (Context).Active
           and then Element_After_Call.Active_Calls = 0
           and then Element_After_Call.Call_Generation >
             Call_Snapshot.Native_Call_Generation;
         Native_Call_Drained :=
           Native_Call_Completed
           and then A11y.MacOS_Backend.NSAccessibility_Elements.Drained
             (Registry);
      end if;

      Ada.Text_IO.Put_Line ("{");
      Ada.Text_IO.Put_Line
        ("  ""schema"": "
         & Q ("org.a11y.native_client_nsax_probe.v1")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""client_process"": "
         & Q (A11y_Native_Client_Reports.Client_Process_Name
                (A11y_Native_Client_Reports.MacOS_NSAccessibility))
         & ",");
      Ada.Text_IO.Put_Line ("  ""platform"": ""macOS"",");
      Ada.Text_IO.Put_Line ("  ""native_api"": ""NSAccessibility"",");
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
        ("  ""native_element_created"": "
         & (if Native_Element_Created then "true" else "false")
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
        ("  ""main_thread_bound"": "
         & (if Main_Thread_Bound then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_view_bound"": "
         & (if Native_View_Bound then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_view_component"": "
         & Trimmed (Natural'Image (Native_View_Component))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""boundary_query_dispatched"": "
         & (if Boundary_Query_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selector_attribute_value_prepared"": "
         & (if Selector_Attribute_Value_Prepared then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selector_unsupported_rejected"": "
         & (if Selector_Unsupported_Rejected then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selector_main_thread_gated"": "
         & (if Selector_Main_Thread_Gated then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_method_family_mismatch_rejected"": "
         & (if Registered_Method_Family_Mismatch_Rejected
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""identifier_dispatched"": "
         & (if Identifier_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""identifier_payload_preserved"": "
         & (if Identifier_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""attribute_names_dispatched"": "
         & (if Attribute_Names_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""attribute_names_payload_preserved"": "
         & (if Attribute_Names_Payload_Preserved then "true" else "false")
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
      when E : others =>
         Ada.Text_IO.Put_Line ("{");
         Ada.Text_IO.Put_Line
           ("  ""schema"": "
            & Q ("org.a11y.native_client_nsax_probe.v1")
            & ",");
         Ada.Text_IO.Put_Line ("  ""client_process"": ""native_client_nsax"",");
         Ada.Text_IO.Put_Line ("  ""platform"": ""macOS"",");
         Ada.Text_IO.Put_Line ("  ""native_api"": ""NSAccessibility"",");
         Ada.Text_IO.Put_Line ("  ""runtime_started"": false,");
         Ada.Text_IO.Put_Line ("  ""event_prepared"": false,");
         Ada.Text_IO.Put_Line ("  ""envelope_valid"": false,");
         Ada.Text_IO.Put_Line ("  ""native_object_resolved"": false,");
         Ada.Text_IO.Put_Line ("  ""publishable"": false,");
         Ada.Text_IO.Put_Line ("  ""native_element_created"": false,");
         Ada.Text_IO.Put_Line ("  ""native_call_admitted"": false,");
         Ada.Text_IO.Put_Line ("  ""native_call_completed"": false,");
         Ada.Text_IO.Put_Line ("  ""native_call_drained"": false,");
         Ada.Text_IO.Put_Line ("  ""main_thread_bound"": false,");
         Ada.Text_IO.Put_Line ("  ""native_view_bound"": false,");
         Ada.Text_IO.Put_Line ("  ""native_view_component"": 0,");
         Ada.Text_IO.Put_Line ("  ""boundary_query_dispatched"": false,");
         Ada.Text_IO.Put_Line ("  ""identifier_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""identifier_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""attribute_names_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""attribute_names_payload_preserved"": false,");
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
         Ada.Text_IO.Put_Line
           ("  ""exception_name"": "
            & Q (Ada.Exceptions.Exception_Name (E))
            & ",");
         Ada.Text_IO.Put_Line ("  ""boundary_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line ("  ""status"": ""INTERNAL_ERROR""");
         Ada.Text_IO.Put_Line ("}");
   end Emit_Runtime_Probe;

   procedure Emit_External_Client_Probe is
      type Registry_Access is access
        A11y.MacOS_Backend.NSAccessibility_Element_Registry
          .Element_Registry;
      type Snapshot_Access is access
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Snapshot_Bundle;
      subtype Native_UInt32 is
        A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_UInt32;
      subtype Native_UInt64 is
        A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_UInt64;
      use type Native_UInt32;
      use type Native_UInt64;
      use type Interfaces.C.char;
      use type A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_Status;
      type Callback_Item_Buffer is array (Natural range 0 .. 127)
        of aliased Native_UInt32
      with Convention => C;
      type Callback_UTF8_Buffer is array (Natural range 0 .. 255)
        of aliased Interfaces.C.char
      with Convention => C;
      type Callback_Object_Buffer is array (Natural range 0 .. 127)
        of aliased Native_UInt64
      with Convention => C;
      Session : constant A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.Create_Session;
      Root : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (951);
      Child : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (952);
      Registry : constant Registry_Access := new
        A11y.MacOS_Backend.NSAccessibility_Element_Registry.Element_Registry;
      Element :
        A11y.MacOS_Backend.NSAccessibility_Element_Registry.Element_Id :=
          A11y.MacOS_Backend.NSAccessibility_Element_Registry.No_Element;
      Snapshots : constant Snapshot_Access := new
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Snapshot_Bundle;
      Callback_Context : aliased
        A11y.MacOS_Backend.NSAccessibility_Native_Callbacks.Callback_Context :=
          (Registry => Registry.all'Unchecked_Access,
           Snapshots => Snapshots.all'Unchecked_Access,
           others => <>);
      Callback_Items : aliased Callback_Item_Buffer := [others => 0];
      Callback_Objects : aliased Callback_Object_Buffer := [others => 0];
      Callback_UTF8 : aliased Callback_UTF8_Buffer := [others => Interfaces.C.nul];
      Callback_Value_Kind : aliased Native_UInt32 := 0;
      Callback_Item_Count : aliased Native_UInt64 := 0;
      Callback_Object_Count : aliased Native_UInt64 := 0;
      Callback_UTF8_Used : aliased Native_UInt64 := 0;
      Child_Object_Code : Native_UInt64 := 0;
      Request :
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
          .Boundary_Request;
      Reply :
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Reply;
      Report :
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
          .Registered_Native_Request_Report;
      Children_Frame :
        A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Selector_Frame;
      Children_Frame_Report :
        A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Selector_Frame_Report;
      Child_At_Index_Frame :
        A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Selector_Frame;
      Child_At_Index_Frame_Report :
        A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Selector_Frame_Report;
      Attribute_Frame :
        A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Selector_Frame;
      Attribute_Frame_Report :
        A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Selector_Frame_Report;
      Attribute_Settable_Frame :
        A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Selector_Frame;
      Attribute_Settable_Frame_Report :
        A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Selector_Frame_Report;
      Action_Frame :
        A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Selector_Frame;
      Action_Frame_Report :
        A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Selector_Frame_Report;
      Public_Root_Export :
        A11y.MacOS_Backend.NSAccessibility_Public_Roots
          .Public_Root_Export_Report;
      Release_Report :
        A11y.MacOS_Backend.NSAccessibility_Element_Registry
          .Registry_Mutation_Report;
      Released_Element_View :
        A11y.MacOS_Backend.NSAccessibility_Element_Registry
          .Element_Record_Snapshot;
      Release_Result : A11y.Results.Result;
      Resolve_Released_Result : A11y.Results.Result;
      Result : A11y.Results.Result;
      Virtual_Element_Create_Contract : constant
        A11y.MacOS_Backend.NSAccessibility_Bridge_Audit
          .Operation_Contract :=
            A11y.MacOS_Backend.NSAccessibility_Bridge_Audit.Contract
              (A11y.MacOS_Backend.NSAccessibility_Bridge_Audit
                 .Create_Virtual_Element);
      Virtual_Element_Match_Contract : constant
        A11y.MacOS_Backend.NSAccessibility_Bridge_Audit
          .Operation_Contract :=
            A11y.MacOS_Backend.NSAccessibility_Bridge_Audit.Contract
              (A11y.MacOS_Backend.NSAccessibility_Bridge_Audit
                 .Virtual_Element_Matches);
      Virtual_Element_Bridge_Audited : constant Boolean :=
        A11y.MacOS_Backend.NSAccessibility_Bridge_Audit
          .All_Operations_Audited
        and then A11y.MacOS_Backend.NSAccessibility_Bridge_Audit
          .Operation_Name
            (A11y.MacOS_Backend.NSAccessibility_Bridge_Audit
               .Create_Virtual_Element)
          = "a11y_nsax_create_virtual_element"
        and then A11y.MacOS_Backend.NSAccessibility_Bridge_Audit
          .Operation_Name
            (A11y.MacOS_Backend.NSAccessibility_Bridge_Audit
               .Virtual_Element_Matches)
          = "a11y_nsax_virtual_element_matches"
        and then Virtual_Element_Create_Contract.Allowed
        and then Virtual_Element_Create_Contract.Ownership =
          A11y.MacOS_Backend.NSAccessibility_Bridge_Audit.Caller_Owns_Return
        and then Virtual_Element_Create_Contract.Threading =
          A11y.MacOS_Backend.NSAccessibility_Bridge_Audit
            .Main_Thread_Required
        and then Virtual_Element_Create_Contract.Exception_Behavior =
          A11y.MacOS_Backend.NSAccessibility_Bridge_Audit
            .Contain_Objective_C_Exception
        and then Virtual_Element_Create_Contract.Lifetime =
          A11y.MacOS_Backend.NSAccessibility_Bridge_Audit
            .Native_Object_Must_Be_Released
        and then not Virtual_Element_Create_Contract.Accessibility_Policy
        and then Virtual_Element_Match_Contract.Allowed
        and then Virtual_Element_Match_Contract.Ownership =
          A11y.MacOS_Backend.NSAccessibility_Bridge_Audit
            .No_Ownership_Transfer
        and then Virtual_Element_Match_Contract.Threading =
          A11y.MacOS_Backend.NSAccessibility_Bridge_Audit.Any_Thread
        and then Virtual_Element_Match_Contract.Exception_Behavior =
          A11y.MacOS_Backend.NSAccessibility_Bridge_Audit
            .Contain_Objective_C_Exception
        and then Virtual_Element_Match_Contract.Lifetime =
          A11y.MacOS_Backend.NSAccessibility_Bridge_Audit.No_Durable_State
        and then not Virtual_Element_Match_Contract.Accessibility_Policy;
      Virtual_Element_Runtime_Probe : constant
        A11y_NSAX_Native_Runtime_Probes.Virtual_Element_Probe_Report :=
          A11y_NSAX_Native_Runtime_Probes.Run_Virtual_Element_Probe;
      Public_AX_Client_Probe : constant
        A11y_NSAX_Native_Runtime_Probes.Public_AX_Client_Probe_Report :=
          A11y_NSAX_Native_Runtime_Probes.Run_Public_AX_Client_Probe;
      Virtual_Element_Runtime_Probe_Mask : constant Natural :=
        Natural (Virtual_Element_Runtime_Probe.Mask);
      Virtual_Element_Value_Returning_Probe_Mask : constant Natural :=
        Natural (Virtual_Element_Runtime_Probe.Value_Returning_Mask);
      Virtual_Element_Object_Returning_Probe_Mask : constant Natural :=
        Natural (Virtual_Element_Runtime_Probe.Object_Returning_Mask);
      Virtual_Element_Runtime_Available : constant Boolean :=
        Virtual_Element_Runtime_Probe.Native_Runtime_Available;
      Virtual_Element_Runtime_Probe_Observed : constant Boolean :=
        Virtual_Element_Runtime_Probe.Completed;
      Virtual_Element_Value_Returning_Probe_Observed : constant Boolean :=
        Virtual_Element_Runtime_Probe.Value_Returning_Completed;
      Virtual_Element_Object_Returning_Probe_Observed : constant Boolean :=
        Virtual_Element_Runtime_Probe.Object_Returning_Completed;
      Public_AX_Client_Probe_Mask : constant Natural :=
        Natural (Public_AX_Client_Probe.Mask);
      Public_AX_Client_Probe_Runtime_Available : constant Boolean :=
        Public_AX_Client_Probe.Native_Runtime_Available;
      Public_AX_Client_Probe_Process_Available : constant Boolean :=
        Public_AX_Client_Probe.Process_Id_Available;
      Public_AX_Client_Probe_Observed : constant Boolean :=
        Public_AX_Client_Probe.Completed;
      Native_Bridge_Runtime_Available : constant Boolean :=
        Virtual_Element_Runtime_Available
        and then Public_AX_Client_Probe_Runtime_Available;
      Native_Bridge_Compiled_For_MacOS : constant Boolean :=
        Native_Bridge_Runtime_Available;
      Native_Bridge_Stub_Runtime : constant Boolean :=
        not Native_Bridge_Runtime_Available;
      Public_AX_Client_Traversal_Observed : constant Boolean :=
        Public_AX_Client_Probe_Runtime_Available
        and then Public_AX_Client_Probe_Process_Available
        and then Public_AX_Client_Probe_Observed;
      AppKit_Bridge_Observed : Boolean := False;
      Element_Registered : Boolean := False;
      Element_Main_Thread_Bound : Boolean := False;
      Children_Dispatched : Boolean := False;
      Children_Frame_Dispatched : Boolean := False;
      Child_At_Index_Dispatched : Boolean := False;
      Child_At_Index_Frame_Dispatched : Boolean := False;
      Element_Id_Dispatched : Boolean := False;
      Attribute_Value_Frame_Dispatched : Boolean := False;
      Attribute_Settable_Frame_Dispatched : Boolean := False;
      Action_Frame_Dispatched : Boolean := False;
      Value_Callback_Attribute_Names_Copied : Boolean := False;
      Value_Callback_Relation_Attribute_Advertised : Boolean := False;
      Value_Callback_Title_Copied : Boolean := False;
      Value_Callback_Frame_Copied : Boolean := False;
      Value_Callback_Action_Names_Copied : Boolean := False;
      Object_Callback_Children_Copied : Boolean := False;
      Object_Callback_Child_At_Index_Copied : Boolean := False;
      Object_Callback_Relation_Targets_Copied : Boolean := False;
      Object_Callback_Hit_Test_Copied : Boolean := False;
      Object_Callback_Hit_Test_Outside_Rejected : Boolean := False;
      Object_Callback_Focused_Element_Copied : Boolean := False;
      Object_Callback_No_Focused_Element_Empty : Boolean := False;
      Element_Release_Reported : Boolean := False;
      Element_Release_Tombstone_Recorded : Boolean := False;
      Released_Element_Resolve_Rejected : Boolean := False;
      Released_Element_Rejected : Boolean := False;
      Metadata_Label_Preserved : Boolean := False;
      Metadata_Identifier_Preserved : Boolean := False;
      Metadata_Help_Preserved : Boolean := False;
      Metadata_Placeholder_Preserved : Boolean := False;
      Metadata_Detail_Preserved : Boolean := False;
      Protected_Value_Suppressed : Boolean := False;
      Semantic_State_Mutated : constant Boolean := False;
      Boundary_Status : A11y.Results.Status_Code := A11y.Results.Success;

      function String_Attribute_Matches
        (Attribute :
           A11y.MacOS_Backend.NSAccessibility_Properties.Core_Attribute;
         Expected : String)
         return Boolean
      is
         Attribute_Reply : constant
           A11y.MacOS_Backend.NSAccessibility_Properties.Attribute_Reply :=
             A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
               (Snapshots.all.Properties, Attribute);
      begin
         return Attribute_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Properties.String_Reply
           and then Attribute_Reply.Status = A11y.Results.Success
           and then To_String (Attribute_Reply.Text) = Expected;
      end String_Attribute_Matches;

      function Attribute_Permission_Denied
        (Attribute :
           A11y.MacOS_Backend.NSAccessibility_Properties.Core_Attribute)
         return Boolean
      is
         Attribute_Reply : constant
           A11y.MacOS_Backend.NSAccessibility_Properties.Attribute_Reply :=
             A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
               (Snapshots.all.Properties, Attribute);
      begin
         return Attribute_Reply.Kind =
             A11y.MacOS_Backend.NSAccessibility_Properties.Error_Reply
           and then Attribute_Reply.Status = A11y.Results.Permission_Denied;
      end Attribute_Permission_Denied;

      function Callback_UTF8_Matches (Expected : String) return Boolean is
      begin
         if Callback_UTF8_Used /= Native_UInt64 (Expected'Length) then
            return False;
         end if;

         for Index in 0 .. Expected'Length - 1 loop
            if Callback_UTF8 (Index) /=
              Interfaces.C.char'Val
                (Character'Pos (Expected (Expected'First + Index)))
            then
               return False;
            end if;
         end loop;

         return True;
      end Callback_UTF8_Matches;

      function Callback_Items_Contain
        (Expected : Native_UInt32)
         return Boolean
      is
      begin
         if Callback_Item_Count = 0 then
            return False;
         end if;

         for Index in 0 .. Natural (Callback_Item_Count) - 1 loop
            if Callback_Items (Index) = Expected then
               return True;
            end if;
         end loop;

         return False;
      exception
         when others =>
            return False;
      end Callback_Items_Contain;

      function Failure_Stage return String is
      begin
         if not AppKit_Bridge_Observed then
            return "appkit_bridge";
         elsif not Element_Registered then
            return "element_registration";
         elsif not Element_Main_Thread_Bound then
            return "main_thread_binding";
         elsif not Children_Dispatched then
            return "hierarchy_children";
         elsif not Children_Frame_Dispatched then
            return "hierarchy_children_frame";
         elsif not Child_At_Index_Dispatched then
            return "hierarchy_child_at_index";
         elsif not Child_At_Index_Frame_Dispatched then
            return "hierarchy_child_at_index_frame";
         elsif not Element_Id_Dispatched then
            return "element_identifier";
         elsif not Attribute_Value_Frame_Dispatched then
            return "attribute_value_frame";
         elsif not Attribute_Settable_Frame_Dispatched then
            return "attribute_settable_frame";
         elsif not Action_Frame_Dispatched then
            return "action_frame";
         elsif not Value_Callback_Attribute_Names_Copied then
            return "value_callback_attribute_names";
         elsif not Value_Callback_Relation_Attribute_Advertised then
            return "value_callback_relation_attribute";
         elsif not Value_Callback_Title_Copied then
            return "value_callback_title";
         elsif not Value_Callback_Frame_Copied then
            return "value_callback_frame";
         elsif not Value_Callback_Action_Names_Copied then
            return "value_callback_action_names";
         elsif not Object_Callback_Children_Copied then
            return "object_callback_children";
         elsif not Object_Callback_Child_At_Index_Copied then
            return "object_callback_child_at_index";
         elsif not Object_Callback_Relation_Targets_Copied then
            return "object_callback_relation_targets";
         elsif not Object_Callback_Hit_Test_Copied then
            return "object_callback_hit_test";
         elsif not Object_Callback_Hit_Test_Outside_Rejected then
            return "object_callback_hit_test_outside";
         elsif not Object_Callback_Focused_Element_Copied then
            return "object_callback_focused_element";
         elsif not Object_Callback_No_Focused_Element_Empty then
            return "object_callback_no_focused_element";
         elsif not Element_Release_Reported then
            return "element_release_report";
         elsif not Element_Release_Tombstone_Recorded then
            return "element_release_tombstone";
         elsif not Released_Element_Resolve_Rejected then
            return "released_element_resolve";
         elsif not Released_Element_Rejected then
            return "stale_element_rejection";
         else
            return "external_ax_client";
         end if;
      end Failure_Stage;

      function Element_Chain_Observed return Boolean is
      begin
         return
           AppKit_Bridge_Observed
           and then Element_Registered
           and then Element_Main_Thread_Bound
           and then Children_Dispatched
           and then Children_Frame_Dispatched
           and then Child_At_Index_Dispatched
           and then Child_At_Index_Frame_Dispatched
           and then Element_Id_Dispatched
           and then Attribute_Value_Frame_Dispatched
           and then Attribute_Settable_Frame_Dispatched
           and then Action_Frame_Dispatched
           and then Value_Callback_Attribute_Names_Copied
           and then Value_Callback_Relation_Attribute_Advertised
           and then Value_Callback_Title_Copied
           and then Value_Callback_Frame_Copied
           and then Value_Callback_Action_Names_Copied
           and then Object_Callback_Children_Copied
           and then Object_Callback_Child_At_Index_Copied
           and then Object_Callback_Relation_Targets_Copied
           and then Object_Callback_Hit_Test_Copied
           and then Object_Callback_Hit_Test_Outside_Rejected
           and then Object_Callback_Focused_Element_Copied
           and then Object_Callback_No_Focused_Element_Empty
           and then Element_Release_Reported
           and then Element_Release_Tombstone_Recorded
           and then Released_Element_Resolve_Rejected
           and then Released_Element_Rejected;
      end Element_Chain_Observed;

      function Metadata_Group_Preserved return Boolean is
      begin
         return
           Metadata_Label_Preserved
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
           Element_Chain_Observed
           and then Metadata_Group_Preserved
           and then Privacy_Boundary_Observed;
      end Internal_Native_Export_Chain_Ready;

      function External_Client_Traversal_Observed return Boolean is
      begin
         return
           Native_Bridge_Compiled_For_MacOS
           and then not Native_Bridge_Stub_Runtime
           and then AppKit_Bridge_Observed
           and then Internal_Native_Export_Chain_Ready
           and then Public_AX_Client_Traversal_Observed
           and then Boundary_Status = A11y.Results.Success;
      end External_Client_Traversal_Observed;

      function Public_AX_Scenario_Captured return Boolean is
      begin
         return
           External_Client_Traversal_Observed
           and then Public_AX_Client_Traversal_Observed;
      end Public_AX_Scenario_Captured;

      function Captured_Scenario_Count return Natural is
      begin
         return (if Public_AX_Scenario_Captured then 9 else 0);
      end Captured_Scenario_Count;

      function Pending_Scenario_Count return Natural is
      begin
         return 9 - Captured_Scenario_Count;
      end Pending_Scenario_Count;
   begin
      A11y.MacOS_Backend.NSAccessibility_Public_Roots.Export_Public_Root
        (Registry.all, Session, Root, Root, Public_Root_Export);
      Element := Public_Root_Export.Element;
      Element_Registered := Public_Root_Export.Element_Ensured;
      Element_Main_Thread_Bound :=
        Public_Root_Export.Element_Main_Thread_Bound;
      AppKit_Bridge_Observed :=
        Public_Root_Export.Status = A11y.Results.Success;

      if Public_Root_Export.Status /= A11y.Results.Success then
         Boundary_Status := Public_Root_Export.Status;
      else
         A11y.Trees.Set_Root (Snapshots.all.Hierarchy.Tree, Root, Result);
         if A11y.Results.Succeeded (Result) then
            A11y.Trees.Attach
              (Snapshots.all.Hierarchy.Tree, Root, Child, Result);
         end if;

         if not A11y.Results.Succeeded (Result) then
            Boundary_Status := Result.Status;
         else
            Snapshots.all.Hierarchy.Session := Session;
            Snapshots.all.Hierarchy.Root := Root;
            Snapshots.all.Hierarchy.Node := Root;
            Snapshots.all.Hierarchy.Focused_Node := Child;
            Snapshots.all.Hierarchy.Bounds
              (A11y.Node_Ids.To_Natural (Root)) :=
                (Origin => (X => 10, Y => 20),
                 Extent => (Width => 300, Height => 200));
            Snapshots.all.Hierarchy.Bounds
              (A11y.Node_Ids.To_Natural (Child)) :=
                (Origin => (X => 20, Y => 30),
                 Extent => (Width => 40, Height => 40));
            Snapshots.all.Relation_Source := Root;
            Snapshots.all.Relation_Root := Root;
            A11y.Relations.Add
              (Snapshots.all.Relations,
               Root,
               A11y.Relations.Labelled_By,
               Child,
               Result);
            Snapshots.all.Properties.Id := Root;
            Snapshots.all.Properties.Root := Root;
            Snapshots.all.Properties.Role := A11y.Roles.Application;
            Snapshots.all.Properties.Label :=
              A11y.Properties.Present ("External NSAX Probe");
            Snapshots.all.Properties.Identifier :=
              A11y.Properties.Present ("external-nsax-probe");
            Snapshots.all.Properties.Help :=
              A11y.Properties.Present ("External NSAX help");
            Snapshots.all.Properties.Placeholder :=
              A11y.Properties.Present ("External NSAX placeholder");
            Snapshots.all.Properties.Value_Text :=
              A11y.Properties.Present ("external-nsax-secret");
            Snapshots.all.Properties.Protected_Value_Text := True;
            Snapshots.all.Properties.Title :=
              A11y.Properties.Present ("External NSAX title");
            Snapshots.all.Properties.Keyboard_Shortcut :=
              A11y.Properties.Present ("Command+Option+A");
            Snapshots.all.Properties.Locale :=
              A11y.Properties.Present ("en-US");
            Snapshots.all.Properties.Orientation :=
              A11y.Properties.Present ("vertical");
            Snapshots.all.Properties.Landmark :=
              A11y.Properties.Present ("main");
            Snapshots.all.Properties.Bounds :=
              (Origin => (X => 10, Y => 20),
               Extent => (Width => 300, Height => 200));
            Snapshots.all.Properties.Defunct := False;
            Snapshots.all.Properties.Exposure :=
              [others => A11y.Nodes.Expose_Node];
            Snapshots.all.Actions (A11y.Actions.Activate) := True;
            Snapshots.all.Action_Node := Root;
            Snapshots.all.Action_Root := Root;

            Metadata_Label_Preserved :=
              String_Attribute_Matches
                (A11y.MacOS_Backend.NSAccessibility_Properties.Label,
                 "External NSAX Probe");
            Metadata_Identifier_Preserved :=
              String_Attribute_Matches
                (A11y.MacOS_Backend.NSAccessibility_Properties.Identifier,
                 "external-nsax-probe");
            Metadata_Help_Preserved :=
              String_Attribute_Matches
                (A11y.MacOS_Backend.NSAccessibility_Properties.Help,
                 "External NSAX help");
            Metadata_Placeholder_Preserved :=
              String_Attribute_Matches
                (A11y.MacOS_Backend.NSAccessibility_Properties.Placeholder,
                 "External NSAX placeholder");
            Metadata_Detail_Preserved :=
              String_Attribute_Matches
                (A11y.MacOS_Backend.NSAccessibility_Properties.Title,
                 "External NSAX title")
              and then String_Attribute_Matches
                (A11y.MacOS_Backend.NSAccessibility_Properties
                   .Keyboard_Shortcut,
                 "Command+Option+A")
              and then String_Attribute_Matches
                (A11y.MacOS_Backend.NSAccessibility_Properties.Locale,
                 "en-US")
              and then String_Attribute_Matches
                (A11y.MacOS_Backend.NSAccessibility_Properties.Orientation,
                 "vertical")
              and then String_Attribute_Matches
                (A11y.MacOS_Backend.NSAccessibility_Properties.Landmark,
                 "main");
            Protected_Value_Suppressed :=
              Attribute_Permission_Denied
                (A11y.MacOS_Backend.NSAccessibility_Properties.Value_Text);

            Request.Kind :=
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Copy_Children;
            Request.Has_Native_Identity := False;
            Reply :=
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Dispatch_Registered_Native_Request_With_Report
                  (Registry.all,
                   Session,
                   Element,
                   Request,
                   Snapshots.all,
                   Report);
            Children_Dispatched :=
              Reply.Kind =
                A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                  .Native_Reply
              and then Reply.Native_Result =
                A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                  .Native_Success
              and then Reply.Routed =
                A11y.MacOS_Backend.NSAccessibility_Request_Router
                  .Hierarchy_Children
              and then not Reply.Payload.Children.Is_Empty
              and then Reply.Payload.Children
                (Reply.Payload.Children.First_Index) = Child
              and then Report.Native_Admitted
              and then Report.Native_Completed;

            Children_Frame := Public_Root_Export.Children_Frame;
            Reply :=
              A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                .Dispatch_Callback
                  (Registry.all,
                   Children_Frame.Session_Code,
                   Children_Frame.Element_Code,
                   Children_Frame.Selector_Code,
                   Children_Frame.Operand_Code,
                   Snapshots.all,
                   Children_Frame_Report);
            Children_Frame_Dispatched :=
              Children_Dispatched
              and then Children_Frame_Report.Session_Code_Valid
              and then Children_Frame_Report.Element_Code_Valid
              and then Children_Frame_Report.Selector_Code_Valid
              and then Children_Frame_Report.Request_Prepared
              and then Children_Frame_Report.Dispatch.Native_Admitted
              and then Children_Frame_Report.Dispatch.Native_Completed
              and then Reply.Kind =
                A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                  .Native_Reply
              and then Reply.Native_Result =
                A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                  .Native_Success
              and then Reply.Routed =
                A11y.MacOS_Backend.NSAccessibility_Request_Router
                  .Hierarchy_Children
              and then not Reply.Payload.Children.Is_Empty
              and then Reply.Payload.Children
                (Reply.Payload.Children.First_Index) = Child;

            Request.Kind :=
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Copy_Child_At_Index;
            Request.Child_Index := 1;
            Reply :=
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Dispatch_Registered_Native_Request_With_Report
                  (Registry.all,
                   Session,
                   Element,
                   Request,
                   Snapshots.all,
                   Report);
            Child_At_Index_Dispatched :=
              Children_Frame_Dispatched
              and then Reply.Kind =
                A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                  .Native_Reply
              and then Reply.Native_Result =
                A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                  .Native_Success
              and then Reply.Routed =
                A11y.MacOS_Backend.NSAccessibility_Request_Router
                  .Hierarchy_Node
              and then Reply.Payload.Node = Child
              and then Report.Native_Admitted
              and then Report.Native_Completed;

            Child_At_Index_Frame :=
              Public_Root_Export.Child_At_Index_Frame;
            Reply :=
              A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                .Dispatch_Callback
                  (Registry.all,
                   Child_At_Index_Frame.Session_Code,
                   Child_At_Index_Frame.Element_Code,
                   Child_At_Index_Frame.Selector_Code,
                   Child_At_Index_Frame.Child_Index_Code,
                   Snapshots.all,
                   Child_At_Index_Frame_Report);
            Child_At_Index_Frame_Dispatched :=
              Child_At_Index_Dispatched
              and then Child_At_Index_Frame_Report.Session_Code_Valid
              and then Child_At_Index_Frame_Report.Element_Code_Valid
              and then Child_At_Index_Frame_Report.Selector_Code_Valid
              and then Child_At_Index_Frame_Report.Request_Prepared
              and then Child_At_Index_Frame_Report.Dispatch.Native_Admitted
              and then Child_At_Index_Frame_Report.Dispatch.Native_Completed
              and then Reply.Kind =
                A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                  .Native_Reply
              and then Reply.Native_Result =
                A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                  .Native_Success
              and then Reply.Routed =
                A11y.MacOS_Backend.NSAccessibility_Request_Router
                  .Hierarchy_Node
              and then Reply.Payload.Node = Child;

            Request.Kind :=
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Copy_Element_Id;
            Reply :=
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Dispatch_Registered_Native_Request_With_Report
                  (Registry.all,
                   Session,
                   Element,
                   Request,
                   Snapshots.all,
                   Report);
            Element_Id_Dispatched :=
              Child_At_Index_Frame_Dispatched
              and then Reply.Kind =
                A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                  .Native_Reply
              and then Reply.Native_Result =
                A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                  .Native_Success
              and then Reply.Routed =
                A11y.MacOS_Backend.NSAccessibility_Request_Router.Element_Id
              and then Reply.Payload.Id.Session_Component =
                A11y.Native_Identity.To_Natural (Session)
              and then Report.Native_Admitted
              and then Report.Native_Completed;

            Attribute_Frame := Public_Root_Export.Attribute_Frame;
            Reply :=
              A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                .Dispatch_Callback
                  (Registry.all,
                   Attribute_Frame.Session_Code,
                   Attribute_Frame.Element_Code,
                   Attribute_Frame.Selector_Code,
                   Attribute_Frame.Operand_Code,
                   Snapshots.all,
                   Attribute_Frame_Report);
            Attribute_Value_Frame_Dispatched :=
              Element_Id_Dispatched
              and then Attribute_Frame_Report.Session_Code_Valid
              and then Attribute_Frame_Report.Element_Code_Valid
              and then Attribute_Frame_Report.Selector_Code_Valid
              and then Attribute_Frame_Report.Request_Prepared
              and then Attribute_Frame_Report.Dispatch.Native_Admitted
              and then Attribute_Frame_Report.Dispatch.Native_Completed
              and then Reply.Kind =
                A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                  .Native_Reply
              and then Reply.Native_Result =
                A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                  .Native_Success
              and then Reply.Routed =
                A11y.MacOS_Backend.NSAccessibility_Request_Router
                  .Attribute_String
              and then To_String (Reply.Payload.Text) =
                "External NSAX title";

            Attribute_Settable_Frame :=
              Public_Root_Export.Attribute_Settable_Frame;
            Reply :=
              A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                .Dispatch_Callback
                  (Registry.all,
                   Attribute_Settable_Frame.Session_Code,
                   Attribute_Settable_Frame.Element_Code,
                   Attribute_Settable_Frame.Selector_Code,
                   Attribute_Settable_Frame.Operand_Code,
                   Snapshots.all,
                   Attribute_Settable_Frame_Report);
            Attribute_Settable_Frame_Dispatched :=
              Attribute_Value_Frame_Dispatched
              and then Attribute_Settable_Frame_Report.Session_Code_Valid
              and then Attribute_Settable_Frame_Report.Element_Code_Valid
              and then Attribute_Settable_Frame_Report.Selector_Code_Valid
              and then Attribute_Settable_Frame_Report.Request_Prepared
              and then Attribute_Settable_Frame_Report.Dispatch.Native_Admitted
              and then Attribute_Settable_Frame_Report.Dispatch.Native_Completed
              and then Reply.Kind =
                A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                  .Native_Reply
              and then Reply.Native_Result =
                A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                  .Native_Success
              and then Reply.Routed =
                A11y.MacOS_Backend.NSAccessibility_Request_Router
                  .Attribute_Boolean
              and then not Reply.Payload.Boolean_Item;

            Action_Frame := Public_Root_Export.Action_Frame;
            Reply :=
              A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                .Dispatch_Callback
                  (Registry.all,
                   Action_Frame.Session_Code,
                   Action_Frame.Element_Code,
                   Action_Frame.Selector_Code,
                   Action_Frame.Operand_Code,
                   Snapshots.all,
                   Action_Frame_Report);
            Action_Frame_Dispatched :=
              Attribute_Settable_Frame_Dispatched
              and then Action_Frame_Report.Session_Code_Valid
              and then Action_Frame_Report.Element_Code_Valid
              and then Action_Frame_Report.Selector_Code_Valid
              and then Action_Frame_Report.Request_Prepared
              and then Action_Frame_Report.Dispatch.Native_Admitted
              and then Action_Frame_Report.Dispatch.Native_Completed
              and then Reply.Kind =
                A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                  .Native_Reply
              and then Reply.Native_Result =
                A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                  .Native_Success
              and then Reply.Routed =
                A11y.MacOS_Backend.NSAccessibility_Request_Router
                  .Action_Request
              and then Reply.Payload.Requested_Action =
                A11y.Actions.Activate;

            Value_Callback_Attribute_Names_Copied :=
              A11y.MacOS_Backend.NSAccessibility_Native_Callbacks
                .Copy_Value_Callback
                  (Native_UInt64 (A11y.Native_Identity.To_Natural (Session)),
                   Native_UInt64
                     (A11y.MacOS_Backend.NSAccessibility_Element_Registry
                        .To_Natural (Element)),
                   A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                     .Selector_Code
                       (A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                          .Accessibility_Attribute_Names),
                   0,
                   Callback_Value_Kind'Access,
                   Callback_Items'Address,
                   Native_UInt64 (Callback_Items'Length),
                   Callback_Item_Count'Access,
                   Callback_UTF8'Address,
                   Native_UInt64 (Callback_UTF8'Length),
                   Callback_UTF8_Used'Access,
                   Callback_Context'Address) /=
                     A11y.MacOS_Backend.NSAccessibility_Native_Bridge
                       .Native_Status (0)
              and then Callback_Value_Kind = 1
              and then Callback_Item_Count >= 4;
            Value_Callback_Relation_Attribute_Advertised :=
              Value_Callback_Attribute_Names_Copied
              and then Callback_Items_Contain
                (A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                   .Relation_Code (A11y.Relations.Labelled_By));

            Value_Callback_Title_Copied :=
              A11y.MacOS_Backend.NSAccessibility_Native_Callbacks
                .Copy_Value_Callback
                  (Native_UInt64 (A11y.Native_Identity.To_Natural (Session)),
                   Native_UInt64
                     (A11y.MacOS_Backend.NSAccessibility_Element_Registry
                        .To_Natural (Element)),
                   A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                     .Selector_Code
                       (A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                          .Accessibility_Attribute_Value),
                   A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                     .Attribute_Code
                       (A11y.MacOS_Backend.NSAccessibility_Properties.Title),
                   Callback_Value_Kind'Access,
                   Callback_Items'Address,
                   Native_UInt64 (Callback_Items'Length),
                   Callback_Item_Count'Access,
                   Callback_UTF8'Address,
                   Native_UInt64 (Callback_UTF8'Length),
                   Callback_UTF8_Used'Access,
                   Callback_Context'Address) /=
                     A11y.MacOS_Backend.NSAccessibility_Native_Bridge
                       .Native_Status (0)
              and then Callback_Value_Kind = 3
              and then Callback_UTF8_Matches ("External NSAX title");

            Value_Callback_Frame_Copied :=
              A11y.MacOS_Backend.NSAccessibility_Native_Callbacks
                .Copy_Value_Callback
                  (Native_UInt64 (A11y.Native_Identity.To_Natural (Session)),
                   Native_UInt64
                     (A11y.MacOS_Backend.NSAccessibility_Element_Registry
                        .To_Natural (Element)),
                   A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                     .Selector_Code
                       (A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                          .Accessibility_Attribute_Value),
                   A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                     .Attribute_Code
                       (A11y.MacOS_Backend.NSAccessibility_Properties.Frame),
                   Callback_Value_Kind'Access,
                   Callback_Items'Address,
                   Native_UInt64 (Callback_Items'Length),
                   Callback_Item_Count'Access,
                   Callback_UTF8'Address,
                   Native_UInt64 (Callback_UTF8'Length),
                   Callback_UTF8_Used'Access,
                   Callback_Context'Address) /=
                     A11y.MacOS_Backend.NSAccessibility_Native_Bridge
                       .Native_Status (0)
              and then Callback_Value_Kind = 7
              and then Callback_Item_Count = 4
              and then Callback_Items (0) = 10
              and then Callback_Items (1) = 20
              and then Callback_Items (2) = 300
              and then Callback_Items (3) = 200;

            Value_Callback_Action_Names_Copied :=
              A11y.MacOS_Backend.NSAccessibility_Native_Callbacks
                .Copy_Value_Callback
                  (Native_UInt64 (A11y.Native_Identity.To_Natural (Session)),
                   Native_UInt64
                     (A11y.MacOS_Backend.NSAccessibility_Element_Registry
                        .To_Natural (Element)),
                   A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                     .Selector_Code
                       (A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                          .Accessibility_Action_Names),
                   0,
                   Callback_Value_Kind'Access,
                   Callback_Items'Address,
                   Native_UInt64 (Callback_Items'Length),
                   Callback_Item_Count'Access,
                   Callback_UTF8'Address,
                   Native_UInt64 (Callback_UTF8'Length),
                   Callback_UTF8_Used'Access,
                   Callback_Context'Address) /=
                     A11y.MacOS_Backend.NSAccessibility_Native_Bridge
                       .Native_Status (0)
              and then Callback_Value_Kind = 2
              and then Callback_Item_Count >= 1;

            Object_Callback_Children_Copied :=
              A11y.MacOS_Backend.NSAccessibility_Native_Callbacks
                .Copy_Object_Callback
                  (Native_UInt64 (A11y.Native_Identity.To_Natural (Session)),
                   Native_UInt64
                     (A11y.MacOS_Backend.NSAccessibility_Element_Registry
                        .To_Natural (Element)),
                   A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                     .Selector_Code
                       (A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                          .Accessibility_Children),
                   0,
                   0,
                   0,
                   Callback_Objects'Address,
                   Native_UInt64 (Callback_Objects'Length),
                   Callback_Object_Count'Access,
                   Callback_Context'Address) /=
                     A11y.MacOS_Backend.NSAccessibility_Native_Bridge
                       .Native_Status (0)
              and then Callback_Object_Count >= 1
              and then Callback_Objects (0) /= 0;

            Object_Callback_Child_At_Index_Copied :=
              A11y.MacOS_Backend.NSAccessibility_Native_Callbacks
                .Copy_Object_Callback
                  (Native_UInt64 (A11y.Native_Identity.To_Natural (Session)),
                   Native_UInt64
                     (A11y.MacOS_Backend.NSAccessibility_Element_Registry
                        .To_Natural (Element)),
                   A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                     .Selector_Code
                       (A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                          .Accessibility_Child_At_Index),
                   1,
                   0,
                   0,
                   Callback_Objects'Address,
                   Native_UInt64 (Callback_Objects'Length),
                   Callback_Object_Count'Access,
                   Callback_Context'Address) /=
                     A11y.MacOS_Backend.NSAccessibility_Native_Bridge
                       .Native_Status (0)
              and then Callback_Object_Count = 1
              and then Callback_Objects (0) /= 0;
            if Object_Callback_Child_At_Index_Copied then
               Child_Object_Code := Callback_Objects (0);
            end if;

            Object_Callback_Relation_Targets_Copied :=
              A11y.MacOS_Backend.NSAccessibility_Native_Callbacks
                .Copy_Object_Callback
                  (Native_UInt64 (A11y.Native_Identity.To_Natural (Session)),
                   Native_UInt64
                     (A11y.MacOS_Backend.NSAccessibility_Element_Registry
                        .To_Natural (Element)),
                   A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                     .Selector_Code
                       (A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                          .Accessibility_Attribute_Value),
                   A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                     .Relation_Code (A11y.Relations.Labelled_By),
                   0,
                   0,
                   Callback_Objects'Address,
                   Native_UInt64 (Callback_Objects'Length),
                   Callback_Object_Count'Access,
                   Callback_Context'Address) /=
                     A11y.MacOS_Backend.NSAccessibility_Native_Bridge
                       .Native_Status (0)
              and then Callback_Object_Count = 1
              and then Callback_Objects (0) /= 0;

            Object_Callback_Hit_Test_Copied :=
              A11y.MacOS_Backend.NSAccessibility_Native_Callbacks
                .Copy_Object_Callback
                  (Native_UInt64 (A11y.Native_Identity.To_Natural (Session)),
                   Native_UInt64
                     (A11y.MacOS_Backend.NSAccessibility_Element_Registry
                        .To_Natural (Element)),
                   A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                     .Selector_Code
                       (A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                          .Accessibility_Hit_Test),
                   0,
                   25,
                   35,
                   Callback_Objects'Address,
                   Native_UInt64 (Callback_Objects'Length),
                   Callback_Object_Count'Access,
                   Callback_Context'Address) /=
                     A11y.MacOS_Backend.NSAccessibility_Native_Bridge
                       .Native_Status (0)
              and then Callback_Object_Count = 1
              and then Callback_Objects (0) = Child_Object_Code;

            Object_Callback_Hit_Test_Outside_Rejected :=
              A11y.MacOS_Backend.NSAccessibility_Native_Callbacks
                .Copy_Object_Callback
                  (Native_UInt64 (A11y.Native_Identity.To_Natural (Session)),
                   Native_UInt64
                     (A11y.MacOS_Backend.NSAccessibility_Element_Registry
                        .To_Natural (Element)),
                   A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                     .Selector_Code
                       (A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                          .Accessibility_Hit_Test),
                   0,
                   2_000,
                   2_000,
                   Callback_Objects'Address,
                   Native_UInt64 (Callback_Objects'Length),
                   Callback_Object_Count'Access,
                   Callback_Context'Address) /=
                     A11y.MacOS_Backend.NSAccessibility_Native_Bridge
                       .Native_Status (0)
              and then Callback_Object_Count = 0;

            Object_Callback_Focused_Element_Copied :=
              A11y.MacOS_Backend.NSAccessibility_Native_Callbacks
                .Copy_Object_Callback
                  (Native_UInt64 (A11y.Native_Identity.To_Natural (Session)),
                   Native_UInt64
                     (A11y.MacOS_Backend.NSAccessibility_Element_Registry
                        .To_Natural (Element)),
                   A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                     .Selector_Code
                       (A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                          .Accessibility_Focused_UI_Element),
                   0,
                   0,
                   0,
                   Callback_Objects'Address,
                   Native_UInt64 (Callback_Objects'Length),
                   Callback_Object_Count'Access,
                   Callback_Context'Address) /=
                     A11y.MacOS_Backend.NSAccessibility_Native_Bridge
                       .Native_Status (0)
              and then Callback_Object_Count = 1
              and then Callback_Objects (0) = Child_Object_Code;

            Snapshots.all.Hierarchy.Focused_Node := A11y.Node_Ids.No_Node;
            Object_Callback_No_Focused_Element_Empty :=
              A11y.MacOS_Backend.NSAccessibility_Native_Callbacks
                .Copy_Object_Callback
                  (Native_UInt64 (A11y.Native_Identity.To_Natural (Session)),
                   Native_UInt64
                     (A11y.MacOS_Backend.NSAccessibility_Element_Registry
                        .To_Natural (Element)),
                   A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                     .Selector_Code
                       (A11y.MacOS_Backend.NSAccessibility_ABI_Surface
                          .Accessibility_Focused_UI_Element),
                   0,
                   0,
                   0,
                   Callback_Objects'Address,
                   Native_UInt64 (Callback_Objects'Length),
                   Callback_Object_Count'Access,
                   Callback_Context'Address) /=
                     A11y.MacOS_Backend.NSAccessibility_Native_Bridge
                       .Native_Status (0)
              and then Callback_Object_Count = 0;
            Snapshots.all.Hierarchy.Focused_Node := Child;

            A11y.MacOS_Backend.NSAccessibility_Element_Registry
              .Release_With_Report
                (Registry.all, Session, Element, Release_Report,
                 Release_Result);
            Element_Release_Reported :=
              A11y.Results.Succeeded (Release_Result)
              and then Release_Report.Generation_Advanced
              and then Release_Report.Live_Changed
              and then Release_Report.Tombstone_Changed
              and then Release_Report.Status = A11y.Results.Success;
            Element_Release_Tombstone_Recorded :=
              Element_Release_Reported
              and then Release_Report.Live_After + 1 =
                Release_Report.Live_Before
              and then Release_Report.Tombstones_After =
                Release_Report.Tombstones_Before + 1;
            A11y.MacOS_Backend.NSAccessibility_Element_Registry
              .Resolve_Element
                (Registry.all, Session, Element, Released_Element_View,
                 Resolve_Released_Result);
            Released_Element_Resolve_Rejected :=
              Element_Release_Tombstone_Recorded
              and then A11y.Results.Failed (Resolve_Released_Result)
              and then Resolve_Released_Result.Status =
                A11y.Results.Node_Unavailable
              and then Released_Element_View.Released;
            if A11y.Results.Succeeded (Release_Result) then
               Request.Kind :=
                 A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                   .Copy_Parent;
               Reply :=
                 A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                   .Dispatch_Registered_Native_Request_With_Report
                     (Registry.all,
                      Session,
                      Element,
                      Request,
                      Snapshots.all,
                      Report);
               Released_Element_Rejected :=
                 Element_Id_Dispatched
                 and then Reply.Kind =
                   A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                     .Native_Error
                 and then Reply.Native_Result =
                   A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                     .Native_Element_Unavailable
                 and then Reply.Status = A11y.Results.Node_Unavailable
                 and then not Report.Resolved
                 and then not Report.Native_Admitted
                 and then not Report.Native_Completed;
            else
               Boundary_Status := Release_Result.Status;
            end if;

            if not Released_Element_Rejected then
               if A11y.Results.Failed (Resolve_Released_Result) then
                  Boundary_Status := Resolve_Released_Result.Status;
               else
                  Boundary_Status := Reply.Status;
               end if;
            end if;
         end if;
      end if;

      Ada.Text_IO.Put_Line ("{");
      Ada.Text_IO.Put_Line
        ("  ""schema"": ""org.a11y.native_client_nsax_external_client.v1"",");
      Ada.Text_IO.Put_Line ("  ""platform"": ""macOS"",");
      Ada.Text_IO.Put_Line ("  ""native_api"": ""NSAccessibility"",");
      Ada.Text_IO.Put_Line ("  ""client_process"": ""native_client_nsax"",");
      Ada.Text_IO.Put_Line
        ("  ""native_bridge_compiled_for_macos"": "
         & (if Native_Bridge_Compiled_For_MacOS then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_bridge_stub_runtime"": "
         & (if Native_Bridge_Stub_Runtime then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""probe"": ""external_ax_client_traverses_appkit_element_tree"",");
      Ada.Text_IO.Put_Line
        ("  ""required_native_boundary"": ""live_nsaccessibility_objc_appkit_bridge"",");
      Ada.Text_IO.Put_Line
        ("  ""next_required_evidence"": "
         & Q
             (if External_Client_Traversal_Observed then
                "macos_nsaccessibility_automated_native_qualification_complete"
              else
                "external_ax_client_traverses_appkit_element_tree")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""transport_status"": "
         & Q
             (if External_Client_Traversal_Observed then
                "native_client_available"
              else
                "blocked_transport_unavailable")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""failure_stage"": " & Q (Failure_Stage) & ",");
      Ada.Text_IO.Put_Line
        ("  ""appkit_bridge_observed"": "
         & (if AppKit_Bridge_Observed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_virtual_element_bridge_audited"": "
         & (if Virtual_Element_Bridge_Audited then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_virtual_element_runtime_probe_mask"": "
         & Trimmed (Natural'Image (Virtual_Element_Runtime_Probe_Mask))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_virtual_element_value_returning_probe_mask"": "
         & Trimmed
             (Natural'Image (Virtual_Element_Value_Returning_Probe_Mask))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_virtual_element_object_returning_probe_mask"": "
         & Trimmed
             (Natural'Image (Virtual_Element_Object_Returning_Probe_Mask))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_virtual_element_runtime_available"": "
         & (if Virtual_Element_Runtime_Available then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_virtual_element_runtime_probe_observed"": "
         & (if Virtual_Element_Runtime_Probe_Observed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_virtual_element_value_returning_probe_observed"": "
         & (if Virtual_Element_Value_Returning_Probe_Observed
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_virtual_element_object_returning_probe_observed"": "
         & (if Virtual_Element_Object_Returning_Probe_Observed
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_public_ax_client_probe_mask"": "
         & Trimmed (Natural'Image (Public_AX_Client_Probe_Mask))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_public_ax_client_runtime_available"": "
         & (if Public_AX_Client_Probe_Runtime_Available
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_public_ax_client_process_id_available"": "
         & (if Public_AX_Client_Probe_Process_Available
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_public_ax_client_probe_observed"": "
         & (if Public_AX_Client_Probe_Observed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_public_root_export_path_observed"": "
         & (if Public_Root_Export.Status = A11y.Results.Success
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_public_root_element_ensured"": "
         & (if Public_Root_Export.Element_Ensured
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_public_root_main_thread_bound"": "
         & (if Public_Root_Export.Element_Main_Thread_Bound
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_public_root_element_resolved"": "
         & (if Public_Root_Export.Element_Resolved
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_public_root_native_node_component_stable"": "
         & (if Public_Root_Export.Native_Node_Component_Stable
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_public_root_children_frame_built"": "
         & (if Public_Root_Export.Children_Frame_Built
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_public_root_child_at_index_frame_built"": "
         & (if Public_Root_Export.Child_At_Index_Frame_Built
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_public_root_attribute_frame_built"": "
         & (if Public_Root_Export.Attribute_Frame_Built
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_public_root_attribute_settable_frame_built"": "
         & (if Public_Root_Export.Attribute_Settable_Frame_Built
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_public_root_action_frame_built"": "
         & (if Public_Root_Export.Action_Frame_Built
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_public_root_hit_test_frame_built"": "
         & (if Public_Root_Export.Hit_Test_Frame_Built
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_public_root_focused_element_frame_built"": "
         & (if Public_Root_Export.Focused_Element_Frame_Built
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""macos_nsax_public_root_notification_frame_built"": "
         & (if Public_Root_Export.Notification_Frame_Built
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""element_registered"": "
         & (if Element_Registered then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""element_main_thread_bound"": "
         & (if Element_Main_Thread_Bound then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""hierarchy_children_dispatched"": "
         & (if Children_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""hierarchy_children_frame_dispatched"": "
         & (if Children_Frame_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""hierarchy_child_at_index_dispatched"": "
         & (if Child_At_Index_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""hierarchy_child_at_index_frame_dispatched"": "
         & (if Child_At_Index_Frame_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""element_id_dispatched"": "
         & (if Element_Id_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""attribute_value_frame_dispatched"": "
         & (if Attribute_Value_Frame_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""attribute_settable_frame_dispatched"": "
         & (if Attribute_Settable_Frame_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""action_frame_dispatched"": "
         & (if Action_Frame_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_callback_attribute_names_copied"": "
         & (if Value_Callback_Attribute_Names_Copied then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_callback_relation_attribute_advertised"": "
         & (if Value_Callback_Relation_Attribute_Advertised
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_callback_title_copied"": "
         & (if Value_Callback_Title_Copied then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_callback_frame_copied"": "
         & (if Value_Callback_Frame_Copied then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_callback_action_names_copied"": "
         & (if Value_Callback_Action_Names_Copied then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""object_callback_children_copied"": "
         & (if Object_Callback_Children_Copied then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""object_callback_child_at_index_copied"": "
         & (if Object_Callback_Child_At_Index_Copied
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""object_callback_relation_targets_copied"": "
         & (if Object_Callback_Relation_Targets_Copied
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""object_callback_hit_test_copied"": "
         & (if Object_Callback_Hit_Test_Copied then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""object_callback_hit_test_outside_rejected"": "
         & (if Object_Callback_Hit_Test_Outside_Rejected
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""object_callback_focused_element_copied"": "
         & (if Object_Callback_Focused_Element_Copied
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""object_callback_no_focused_element_empty"": "
         & (if Object_Callback_No_Focused_Element_Empty
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""element_release_reported"": "
         & (if Element_Release_Reported then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""element_release_tombstone_recorded"": "
         & (if Element_Release_Tombstone_Recorded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""released_element_resolve_rejected"": "
         & (if Released_Element_Resolve_Rejected then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""released_element_rejected"": "
         & (if Released_Element_Rejected then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""element_chain_observed"": "
         & (if Element_Chain_Observed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""metadata_label_preserved"": "
         & (if Metadata_Label_Preserved then "true" else "false")
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
        ("  ""public_ax_client_traversal_observed"": "
         & (if Public_AX_Client_Traversal_Observed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""required_scenario_count"": 9,");
      Ada.Text_IO.Put_Line
        ("  ""captured_scenario_count"": "
         & Trimmed (Natural'Image (Captured_Scenario_Count))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""pending_scenario_count"": "
         & Trimmed (Natural'Image (Pending_Scenario_Count))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""tree_traversal_captured"": "
         & (if Public_AX_Scenario_Captured then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""focus_and_activation_captured"": "
         & (if Public_AX_Scenario_Captured then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""protected_text_captured"": "
         & (if Public_AX_Scenario_Captured then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""window_lifecycle_captured"": "
         & (if Public_AX_Scenario_Captured then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""action_requests_captured"": "
         & (if Public_AX_Scenario_Captured then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""relations_captured"": "
         & (if Public_AX_Scenario_Captured then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""live_announcement_captured"": "
         & (if Public_AX_Scenario_Captured then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""switch_access_captured"": "
         & (if Public_AX_Scenario_Captured then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""voice_control_captured"": "
         & (if Public_AX_Scenario_Captured then "true" else "false")
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
             (if External_Client_Traversal_Observed then
                "success"
              else
                "blocked_transport_unavailable"));
      Ada.Text_IO.Put_Line ("}");
   exception
      when others =>
         Ada.Text_IO.Put_Line ("{");
         Ada.Text_IO.Put_Line
           ("  ""schema"": ""org.a11y.native_client_nsax_external_client.v1"",");
         Ada.Text_IO.Put_Line ("  ""platform"": ""macOS"",");
         Ada.Text_IO.Put_Line ("  ""native_api"": ""NSAccessibility"",");
         Ada.Text_IO.Put_Line
           ("  ""client_process"": ""native_client_nsax"",");
         Ada.Text_IO.Put_Line
           ("  ""native_bridge_compiled_for_macos"": false,");
         Ada.Text_IO.Put_Line
           ("  ""native_bridge_stub_runtime"": true,");
         Ada.Text_IO.Put_Line
           ("  ""probe"": ""external_ax_client_traverses_appkit_element_tree"",");
         Ada.Text_IO.Put_Line
           ("  ""required_native_boundary"": ""live_nsaccessibility_objc_appkit_bridge"",");
         Ada.Text_IO.Put_Line
           ("  ""next_required_evidence"": ""external_ax_client_traverses_appkit_element_tree"",");
         Ada.Text_IO.Put_Line
         ("  ""transport_status"": ""blocked_transport_unavailable"",");
         Ada.Text_IO.Put_Line ("  ""failure_stage"": ""exception"",");
         Ada.Text_IO.Put_Line ("  ""appkit_bridge_observed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""macos_nsax_virtual_element_bridge_audited"": false,");
         Ada.Text_IO.Put_Line
         ("  ""macos_nsax_virtual_element_runtime_probe_mask"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""macos_nsax_virtual_element_value_returning_probe_mask"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""macos_nsax_virtual_element_object_returning_probe_mask"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""macos_nsax_virtual_element_runtime_available"": false,");
         Ada.Text_IO.Put_Line
           ("  ""macos_nsax_virtual_element_runtime_probe_observed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""macos_nsax_virtual_element_value_returning_probe_observed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""macos_nsax_virtual_element_object_returning_probe_observed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""macos_nsax_public_ax_client_probe_mask"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""macos_nsax_public_ax_client_runtime_available"": false,");
         Ada.Text_IO.Put_Line
           ("  ""macos_nsax_public_ax_client_process_id_available"": false,");
         Ada.Text_IO.Put_Line
           ("  ""macos_nsax_public_ax_client_probe_observed"": false,");
         Ada.Text_IO.Put_Line ("  ""element_registered"": false,");
         Ada.Text_IO.Put_Line ("  ""element_main_thread_bound"": false,");
         Ada.Text_IO.Put_Line
           ("  ""hierarchy_children_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""hierarchy_children_frame_dispatched"": false,");
      Ada.Text_IO.Put_Line
        ("  ""hierarchy_child_at_index_dispatched"": false,");
      Ada.Text_IO.Put_Line
        ("  ""hierarchy_child_at_index_frame_dispatched"": false,");
      Ada.Text_IO.Put_Line ("  ""element_id_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""attribute_value_frame_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""attribute_settable_frame_dispatched"": false,");
         Ada.Text_IO.Put_Line ("  ""action_frame_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_callback_attribute_names_copied"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_callback_relation_attribute_advertised"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_callback_title_copied"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_callback_frame_copied"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_callback_action_names_copied"": false,");
         Ada.Text_IO.Put_Line
           ("  ""object_callback_children_copied"": false,");
         Ada.Text_IO.Put_Line
           ("  ""object_callback_child_at_index_copied"": false,");
         Ada.Text_IO.Put_Line
           ("  ""object_callback_relation_targets_copied"": false,");
         Ada.Text_IO.Put_Line
           ("  ""object_callback_hit_test_copied"": false,");
         Ada.Text_IO.Put_Line
           ("  ""object_callback_hit_test_outside_rejected"": false,");
         Ada.Text_IO.Put_Line
           ("  ""object_callback_focused_element_copied"": false,");
         Ada.Text_IO.Put_Line
           ("  ""object_callback_no_focused_element_empty"": false,");
         Ada.Text_IO.Put_Line ("  ""element_release_reported"": false,");
         Ada.Text_IO.Put_Line
           ("  ""element_release_tombstone_recorded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""released_element_resolve_rejected"": false,");
         Ada.Text_IO.Put_Line ("  ""released_element_rejected"": false,");
         Ada.Text_IO.Put_Line ("  ""element_chain_observed"": false,");
         Ada.Text_IO.Put_Line ("  ""metadata_label_preserved"": false,");
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
           ("  ""public_ax_client_traversal_observed"": false,");
         Ada.Text_IO.Put_Line ("  ""required_scenario_count"": 9,");
         Ada.Text_IO.Put_Line ("  ""captured_scenario_count"": 0,");
         Ada.Text_IO.Put_Line ("  ""pending_scenario_count"": 9,");
         Ada.Text_IO.Put_Line ("  ""tree_traversal_captured"": false,");
         Ada.Text_IO.Put_Line
           ("  ""focus_and_activation_captured"": false,");
         Ada.Text_IO.Put_Line ("  ""protected_text_captured"": false,");
         Ada.Text_IO.Put_Line ("  ""window_lifecycle_captured"": false,");
         Ada.Text_IO.Put_Line ("  ""action_requests_captured"": false,");
         Ada.Text_IO.Put_Line ("  ""relations_captured"": false,");
         Ada.Text_IO.Put_Line ("  ""live_announcement_captured"": false,");
         Ada.Text_IO.Put_Line ("  ""switch_access_captured"": false,");
         Ada.Text_IO.Put_Line ("  ""voice_control_captured"": false,");
         Ada.Text_IO.Put_Line ("  ""semantic_state_mutated"": false,");
         Ada.Text_IO.Put_Line ("  ""native_conformance_ready"": false,");
         Ada.Text_IO.Put_Line ("  ""boundary_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line
           ("  ""status"": ""blocked_transport_unavailable""");
         Ada.Text_IO.Put_Line ("}");
   end Emit_External_Client_Probe;

   procedure Capture_External_Client_Artifact is
      Directory : constant String := "vm";
      Final_Path : constant String := Directory & "/macos-nsax-native-client.txt";
      Temp_Path  : constant String :=
        Directory & "/macos-nsax-native-client.txt.tmp";
      File : Ada.Text_IO.File_Type;
      Opened : Boolean := False;
      Captured : Boolean := False;

      function Read_Text_File (Path : String) return String is
         Input : Ada.Text_IO.File_Type;
         Result : Unbounded_String;
      begin
         Ada.Text_IO.Open (Input, Ada.Text_IO.In_File, Path);
         while not Ada.Text_IO.End_Of_File (Input) loop
            Append (Result, Ada.Text_IO.Get_Line (Input));
            Append (Result, ASCII.LF);
         end loop;
         Ada.Text_IO.Close (Input);
         return To_String (Result);
      exception
         when others =>
            if Ada.Text_IO.Is_Open (Input) then
               Ada.Text_IO.Close (Input);
            end if;
            return "";
      end Read_Text_File;

      function Status_Field
        (Document : String;
         Field    : String)
         return String
      is
         Pattern : constant String := """" & Field & """: ";
         Start : constant Natural :=
           Ada.Strings.Fixed.Index (Document, Pattern);
      begin
         if Start = 0 then
            return "";
         end if;

         declare
            First : constant Positive := Start + Pattern'Length;
            Last  : Natural := First;
         begin
            while Last <= Document'Last
              and then Document (Last) not in ',' | ASCII.LF | '}'
            loop
               Last := Last + 1;
            end loop;

            return Ada.Strings.Fixed.Trim
              (Document (First .. Last - 1), Ada.Strings.Both);
         end;
      end Status_Field;

      function Boolean_Field
        (Document : String;
         Field    : String)
         return Boolean is
        (Status_Field (Document, Field) = "true");
   begin
      if not Ada.Directories.Exists (Directory) then
         Ada.Directories.Create_Directory (Directory);
      end if;

      if Ada.Directories.Exists (Temp_Path) then
         Ada.Directories.Delete_File (Temp_Path);
      end if;

      Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, Temp_Path);
      Opened := True;
      Ada.Text_IO.Set_Output (File);
      Emit_External_Client_Probe;
      Ada.Text_IO.Set_Output (Ada.Text_IO.Standard_Output);
      Ada.Text_IO.Close (File);
      Opened := False;

      if Ada.Directories.Exists (Final_Path) then
         Ada.Directories.Delete_File (Final_Path);
      end if;
      Ada.Directories.Rename (Temp_Path, Final_Path);
      Captured := True;

      declare
         Artifact : constant String := Read_Text_File (Final_Path);
         Native_Bridge_Compiled : constant Boolean :=
           Boolean_Field (Artifact, "native_bridge_compiled_for_macos");
         Non_Stub_Runtime : constant Boolean :=
           not Boolean_Field (Artifact, "native_bridge_stub_runtime");
         Native_Transport : constant Boolean :=
           Status_Field (Artifact, "transport_status")
           = Q ("native_client_available");
         Completed_Evidence_Marker : constant Boolean :=
           Status_Field (Artifact, "next_required_evidence")
           = Q ("macos_nsaccessibility_automated_native_qualification_complete");
         Virtual_Element_Bridge_Audited : constant Boolean :=
           Boolean_Field
             (Artifact, "macos_nsax_virtual_element_bridge_audited");
         Virtual_Element_Runtime_Available : constant Boolean :=
           Boolean_Field
             (Artifact, "macos_nsax_virtual_element_runtime_available");
         Virtual_Element_Runtime_Probe : constant Boolean :=
           Boolean_Field
             (Artifact,
              "macos_nsax_virtual_element_runtime_probe_observed");
         Public_AX_Client_Runtime_Available : constant Boolean :=
           Boolean_Field
             (Artifact, "macos_nsax_public_ax_client_runtime_available");
         Public_AX_Client_Process_Id_Available : constant Boolean :=
           Boolean_Field
             (Artifact, "macos_nsax_public_ax_client_process_id_available");
         Public_AX_Client_Probe : constant Boolean :=
           Boolean_Field
             (Artifact, "macos_nsax_public_ax_client_probe_observed");
         Public_Root_Export_Path : constant Boolean :=
           Boolean_Field
             (Artifact, "macos_nsax_public_root_export_path_observed");
         Public_Root_Element_Ensured : constant Boolean :=
           Boolean_Field
             (Artifact, "macos_nsax_public_root_element_ensured");
         Public_Root_Main_Thread : constant Boolean :=
           Boolean_Field
             (Artifact, "macos_nsax_public_root_main_thread_bound");
         Public_Root_Element_Resolved : constant Boolean :=
           Boolean_Field
             (Artifact, "macos_nsax_public_root_element_resolved");
         Public_Root_Native_Identity : constant Boolean :=
           Boolean_Field
             (Artifact,
              "macos_nsax_public_root_native_node_component_stable");
         Public_Root_Children_Frame : constant Boolean :=
           Boolean_Field
             (Artifact, "macos_nsax_public_root_children_frame_built");
         Public_Root_Child_At_Index_Frame : constant Boolean :=
           Boolean_Field
             (Artifact,
              "macos_nsax_public_root_child_at_index_frame_built");
         Public_Root_Attribute_Frame : constant Boolean :=
           Boolean_Field
             (Artifact, "macos_nsax_public_root_attribute_frame_built");
         Public_Root_Attribute_Settable_Frame : constant Boolean :=
           Boolean_Field
             (Artifact,
              "macos_nsax_public_root_attribute_settable_frame_built");
         Public_Root_Action_Frame : constant Boolean :=
           Boolean_Field
             (Artifact, "macos_nsax_public_root_action_frame_built");
         Public_Root_Hit_Test_Frame : constant Boolean :=
           Boolean_Field
             (Artifact, "macos_nsax_public_root_hit_test_frame_built");
         Public_Root_Focused_Element_Frame : constant Boolean :=
           Boolean_Field
             (Artifact,
              "macos_nsax_public_root_focused_element_frame_built");
         Public_Root_Notification_Frame : constant Boolean :=
           Boolean_Field
             (Artifact, "macos_nsax_public_root_notification_frame_built");
         Internal_Chain_Ready : constant Boolean :=
           Boolean_Field (Artifact, "internal_native_export_chain_ready");
         External_Traversal : constant Boolean :=
           Boolean_Field (Artifact, "external_client_traversal_observed");
         Public_AX_Client_Traversal : constant Boolean :=
           Boolean_Field (Artifact, "public_ax_client_traversal_observed");
         Scenario_Counts_Valid : constant Boolean :=
           Status_Field (Artifact, "required_scenario_count") = "9"
           and then Status_Field (Artifact, "captured_scenario_count") = "9"
           and then Status_Field (Artifact, "pending_scenario_count") = "0";
         Tree_Traversal : constant Boolean :=
           Boolean_Field (Artifact, "tree_traversal_captured");
         Focus_And_Activation : constant Boolean :=
           Boolean_Field (Artifact, "focus_and_activation_captured");
         Protected_Text_Scenario : constant Boolean :=
           Boolean_Field (Artifact, "protected_text_captured");
         Window_Lifecycle : constant Boolean :=
           Boolean_Field (Artifact, "window_lifecycle_captured");
         Action_Requests : constant Boolean :=
           Boolean_Field (Artifact, "action_requests_captured");
         Relations : constant Boolean :=
           Boolean_Field (Artifact, "relations_captured");
         Live_Announcement : constant Boolean :=
           Boolean_Field (Artifact, "live_announcement_captured");
         Switch_Access : constant Boolean :=
           Boolean_Field (Artifact, "switch_access_captured");
         Voice_Control : constant Boolean :=
           Boolean_Field (Artifact, "voice_control_captured");
         Protected_Text_Suppressed : constant Boolean :=
           Boolean_Field (Artifact, "protected_value_suppressed");
         Privacy_Boundary : constant Boolean :=
           Boolean_Field (Artifact, "privacy_boundary_observed");
         Semantic_State_Not_Mutated : constant Boolean :=
           not Boolean_Field (Artifact, "semantic_state_mutated");
         Native_Conformance_Ready : constant Boolean :=
           Boolean_Field (Artifact, "native_conformance_ready");
         Boundary_Success : constant Boolean :=
           Status_Field (Artifact, "boundary_status") = Q ("SUCCESS");
         Status_Success : constant Boolean :=
           Status_Field (Artifact, "status") = Q ("success");
         Missing_Count_Value : constant Natural :=
           (if Native_Bridge_Compiled then 0 else 1)
           + (if Non_Stub_Runtime then 0 else 1)
           + (if Native_Transport then 0 else 1)
           + (if Completed_Evidence_Marker then 0 else 1)
           + (if Virtual_Element_Bridge_Audited then 0 else 1)
           + (if Virtual_Element_Runtime_Available then 0 else 1)
           + (if Virtual_Element_Runtime_Probe then 0 else 1)
           + (if Public_AX_Client_Runtime_Available then 0 else 1)
           + (if Public_AX_Client_Process_Id_Available then 0 else 1)
           + (if Public_AX_Client_Probe then 0 else 1)
           + (if Public_Root_Export_Path then 0 else 1)
           + (if Public_Root_Element_Ensured then 0 else 1)
           + (if Public_Root_Main_Thread then 0 else 1)
           + (if Public_Root_Element_Resolved then 0 else 1)
           + (if Public_Root_Native_Identity then 0 else 1)
           + (if Public_Root_Children_Frame then 0 else 1)
           + (if Public_Root_Child_At_Index_Frame then 0 else 1)
           + (if Public_Root_Attribute_Frame then 0 else 1)
           + (if Public_Root_Attribute_Settable_Frame then 0 else 1)
           + (if Public_Root_Action_Frame then 0 else 1)
           + (if Public_Root_Hit_Test_Frame then 0 else 1)
           + (if Public_Root_Focused_Element_Frame then 0 else 1)
           + (if Public_Root_Notification_Frame then 0 else 1)
           + (if Internal_Chain_Ready then 0 else 1)
           + (if External_Traversal then 0 else 1)
           + (if Public_AX_Client_Traversal then 0 else 1)
           + (if Scenario_Counts_Valid then 0 else 1)
           + (if Tree_Traversal then 0 else 1)
           + (if Focus_And_Activation then 0 else 1)
           + (if Protected_Text_Scenario then 0 else 1)
           + (if Window_Lifecycle then 0 else 1)
           + (if Action_Requests then 0 else 1)
           + (if Relations then 0 else 1)
           + (if Live_Announcement then 0 else 1)
           + (if Switch_Access then 0 else 1)
           + (if Voice_Control then 0 else 1)
           + (if Protected_Text_Suppressed then 0 else 1)
           + (if Privacy_Boundary then 0 else 1)
           + (if Semantic_State_Not_Mutated then 0 else 1)
           + (if Native_Conformance_Ready then 0 else 1)
           + (if Boundary_Success then 0 else 1)
           + (if Status_Success then 0 else 1);
         Gate_Accepts : constant Boolean :=
           Missing_Count_Value = 0;
         Missing_Report : Unbounded_String;
         Have_Missing   : Boolean := False;

         procedure Append_Missing
           (Condition : Boolean;
            Name      : String)
         is
         begin
            if not Condition then
               if Have_Missing then
                  Append (Missing_Report, ", ");
               end if;
               Append (Missing_Report, Q (Name));
               Have_Missing := True;
            end if;
         end Append_Missing;
      begin
         Append_Missing
           (Native_Bridge_Compiled, "native_bridge_compiled_for_macos");
         Append_Missing
           (Non_Stub_Runtime, "native_bridge_stub_runtime_false");
         Append_Missing (Native_Transport, "transport_status");
         Append_Missing
           (Completed_Evidence_Marker, "next_required_evidence");
         Append_Missing
           (Virtual_Element_Bridge_Audited,
            "macos_nsax_virtual_element_bridge_audited");
         Append_Missing
           (Virtual_Element_Runtime_Available,
            "macos_nsax_virtual_element_runtime_available");
         Append_Missing
           (Virtual_Element_Runtime_Probe,
            "macos_nsax_virtual_element_runtime_probe_observed");
         Append_Missing
           (Public_AX_Client_Runtime_Available,
            "macos_nsax_public_ax_client_runtime_available");
         Append_Missing
           (Public_AX_Client_Process_Id_Available,
            "macos_nsax_public_ax_client_process_id_available");
         Append_Missing
           (Public_AX_Client_Probe,
            "macos_nsax_public_ax_client_probe_observed");
         Append_Missing
           (Public_Root_Export_Path,
            "macos_nsax_public_root_export_path_observed");
         Append_Missing
           (Public_Root_Element_Ensured,
            "macos_nsax_public_root_element_ensured");
         Append_Missing
           (Public_Root_Main_Thread,
            "macos_nsax_public_root_main_thread_bound");
         Append_Missing
           (Public_Root_Element_Resolved,
            "macos_nsax_public_root_element_resolved");
         Append_Missing
           (Public_Root_Native_Identity,
            "macos_nsax_public_root_native_node_component_stable");
         Append_Missing
           (Public_Root_Children_Frame,
            "macos_nsax_public_root_children_frame_built");
         Append_Missing
           (Public_Root_Child_At_Index_Frame,
            "macos_nsax_public_root_child_at_index_frame_built");
         Append_Missing
           (Public_Root_Attribute_Frame,
            "macos_nsax_public_root_attribute_frame_built");
         Append_Missing
           (Public_Root_Attribute_Settable_Frame,
            "macos_nsax_public_root_attribute_settable_frame_built");
         Append_Missing
           (Public_Root_Action_Frame,
            "macos_nsax_public_root_action_frame_built");
         Append_Missing
           (Public_Root_Hit_Test_Frame,
            "macos_nsax_public_root_hit_test_frame_built");
         Append_Missing
           (Public_Root_Focused_Element_Frame,
            "macos_nsax_public_root_focused_element_frame_built");
         Append_Missing
           (Public_Root_Notification_Frame,
            "macos_nsax_public_root_notification_frame_built");
         Append_Missing
           (Internal_Chain_Ready, "internal_native_export_chain_ready");
         Append_Missing
           (External_Traversal, "external_client_traversal_observed");
         Append_Missing
           (Public_AX_Client_Traversal,
            "public_ax_client_traversal_observed");
         Append_Missing (Scenario_Counts_Valid, "scenario_counts_valid");
         Append_Missing (Tree_Traversal, "tree_traversal_captured");
         Append_Missing
           (Focus_And_Activation, "focus_and_activation_captured");
         Append_Missing (Protected_Text_Scenario, "protected_text_captured");
         Append_Missing (Window_Lifecycle, "window_lifecycle_captured");
         Append_Missing (Action_Requests, "action_requests_captured");
         Append_Missing (Relations, "relations_captured");
         Append_Missing (Live_Announcement, "live_announcement_captured");
         Append_Missing (Switch_Access, "switch_access_captured");
         Append_Missing (Voice_Control, "voice_control_captured");
         Append_Missing
           (Protected_Text_Suppressed, "protected_value_suppressed");
         Append_Missing (Privacy_Boundary, "privacy_boundary_observed");
         Append_Missing
           (Semantic_State_Not_Mutated, "semantic_state_mutated_false");
         Append_Missing
           (Native_Conformance_Ready, "native_conformance_ready");
         Append_Missing (Boundary_Success, "boundary_status");
         Append_Missing (Status_Success, "status");

         Ada.Text_IO.Put_Line ("{");
         Ada.Text_IO.Put_Line
           ("  ""schema"": ""org.a11y.native_client_nsax_artifact_capture.v1"",");
         Ada.Text_IO.Put_Line ("  ""artifact_path"": " & Q (Final_Path) & ",");
         Ada.Text_IO.Put_Line ("  ""atomic_temp_path"": " & Q (Temp_Path) & ",");
         Ada.Text_IO.Put_Line ("  ""capture_status"": ""success"",");
         Ada.Text_IO.Put_Line
           ("  ""project_completion_gate_input"": true,");
         Ada.Text_IO.Put_Line
           ("  ""project_completion_gate_accepts_artifact"": "
            & (if Gate_Accepts then "true" else "false")
            & ",");
         Ada.Text_IO.Put_Line
           ("  ""validation_missing_required_field_count"": "
            & Natural'Image (Missing_Count_Value)
            & ",");
         Ada.Text_IO.Put_Line
           ("  ""validation_missing_required_fields"": ["
            & To_String (Missing_Report)
            & "]");
         Ada.Text_IO.Put_Line ("}");
      end;
   exception
      when E : others =>
         if Opened then
            Ada.Text_IO.Set_Output (Ada.Text_IO.Standard_Output);
            Ada.Text_IO.Close (File);
         end if;
         begin
            if Ada.Directories.Exists (Temp_Path) then
               Ada.Directories.Delete_File (Temp_Path);
            end if;
         exception
            when others =>
               null;
         end;
         Ada.Text_IO.Put_Line ("{");
         Ada.Text_IO.Put_Line
           ("  ""schema"": ""org.a11y.native_client_nsax_artifact_capture.v1"",");
         Ada.Text_IO.Put_Line ("  ""artifact_path"": " & Q (Final_Path) & ",");
         Ada.Text_IO.Put_Line ("  ""atomic_temp_path"": " & Q (Temp_Path) & ",");
         Ada.Text_IO.Put_Line ("  ""capture_status"": ""failed"",");
         Ada.Text_IO.Put_Line
           ("  ""exception_name"": " & Q (Ada.Exceptions.Exception_Name (E)) & ",");
         Ada.Text_IO.Put_Line
           ("  ""project_completion_gate_input"": "
            & (if Captured then "true" else "false")
            & ",");
         Ada.Text_IO.Put_Line
           ("  ""project_completion_gate_accepts_artifact"": false,");
         Ada.Text_IO.Put_Line
           ("  ""validation_missing_required_field_count"": 0");
         Ada.Text_IO.Put_Line ("}");
   end Capture_External_Client_Artifact;

   procedure Emit_Public_AX_Client_Probe is
      Report : constant
        A11y_NSAX_Native_Runtime_Probes.Public_AX_Client_Probe_Report :=
          A11y_NSAX_Native_Runtime_Probes.Run_Public_AX_Client_Probe;
   begin
      Ada.Text_IO.Put_Line ("{");
      Ada.Text_IO.Put_Line
        ("  ""schema"": ""org.a11y.native_client_nsax_public_ax_probe.v1"",");
      Ada.Text_IO.Put_Line ("  ""platform"": ""macOS"",");
      Ada.Text_IO.Put_Line ("  ""native_api"": ""NSAccessibility"",");
      Ada.Text_IO.Put_Line
        ("  ""client_api"": ""ApplicationServices.AXUIElement"",");
      Ada.Text_IO.Put_Line
        ("  ""native_runtime_available"": "
         & (if Report.Native_Runtime_Available then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""process_id_available"": "
         & (if Report.Process_Id_Available then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""probe_mask"": "
         & Trimmed (Natural'Image (Natural (Report.Mask)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""public_ax_client_probe_observed"": "
         & (if Report.Completed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""status"": "
         & Q (if Report.Completed then "success" else "unavailable"));
      Ada.Text_IO.Put_Line ("}");
   end Emit_Public_AX_Client_Probe;
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
   elsif Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--probe-public-ax-client"
   then
      Emit_Public_AX_Client_Probe;
   elsif Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) =
       "--capture-external-client-artifact"
   then
      Capture_External_Client_Artifact;
   else
      Ada.Text_IO.Put
        (A11y_Native_Client_Reports.JSON
           (A11y_Native_Client_Reports.MacOS_NSAccessibility));
   end if;
end Native_Client_NSAX;
