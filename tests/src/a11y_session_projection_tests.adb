with A11y.Capabilities;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Registry;
with A11y.Relations;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Roles;
with A11y.Sessions;
with A11y.Trees;

with A11ykit_Test_Support;
with A11y_Node_Provider_Fixtures; use A11y_Node_Provider_Fixtures;

package body A11y_Session_Projection_Tests is
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Results.Status_Code;

   procedure Check (Condition : Boolean; Message : String)
      renames A11ykit_Test_Support.Check;

   procedure Run_Exposure_Projection_Tests is
      Session : A11y.Sessions.Semantic_Session;
      Root_Provider : aliased Exposure_Test_Node :=
        (Test_Node_Provider with Policy => A11y.Nodes.Expose_Node);
      Flattened_Provider : aliased Exposure_Test_Node :=
        (Test_Node_Provider with Policy => A11y.Nodes.Flatten_Node);
      Button_Provider : aliased Exposure_Test_Node :=
        (Test_Node_Provider with Policy => A11y.Nodes.Expose_Node);
      Hidden_Provider : aliased Exposure_Test_Node :=
        (Test_Node_Provider with
         Policy => A11y.Nodes.Hide_Node_And_Subtree);
      Hidden_Button_Provider : aliased Exposure_Test_Node :=
        (Test_Node_Provider with Policy => A11y.Nodes.Expose_Node);
      Descendants_Only_Provider : aliased Exposure_Test_Node :=
        (Test_Node_Provider with
         Policy => A11y.Nodes.Expose_Descendants_Only);
      List_Item_Provider : aliased Exposure_Test_Node :=
        (Test_Node_Provider with Policy => A11y.Nodes.Expose_Node);
      Invalid_Provider : aliased Exposure_Test_Node :=
        (Test_Node_Provider with Policy => A11y.Nodes.Expose_Node);
      Root_Id : A11y.Node_Ids.Node_Id;
      Flattened_Id : A11y.Node_Ids.Node_Id;
      Button_Id : A11y.Node_Ids.Node_Id;
      Hidden_Id : A11y.Node_Ids.Node_Id;
      Hidden_Button_Id : A11y.Node_Ids.Node_Id;
      Descendants_Only_Id : A11y.Node_Ids.Node_Id;
      List_Item_Id : A11y.Node_Ids.Node_Id;
      Invalid_Id : A11y.Node_Ids.Node_Id;
      Children : A11y.Trees.Child_Vectors.Vector;
      Targets : A11y.Relations.Target_Vectors.Vector;
      Result : A11y.Results.Result;
      Parent : A11y.Node_Ids.Node_Id;
      Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
   begin
      A11y.Sessions.Create_Node
        (Session, Root_Provider'Unchecked_Access, Root_Id, Result);
      A11y.Sessions.Create_Node
        (Session, Flattened_Provider'Unchecked_Access, Flattened_Id, Result);
      A11y.Sessions.Create_Node
        (Session, Button_Provider'Unchecked_Access, Button_Id, Result);
      A11y.Sessions.Create_Node
        (Session, Hidden_Provider'Unchecked_Access, Hidden_Id, Result);
      A11y.Sessions.Create_Node
        (Session, Hidden_Button_Provider'Unchecked_Access, Hidden_Button_Id, Result);
      A11y.Sessions.Create_Node
        (Session,
         Descendants_Only_Provider'Unchecked_Access,
         Descendants_Only_Id,
         Result);
      A11y.Sessions.Create_Node
        (Session, List_Item_Provider'Unchecked_Access, List_Item_Id, Result);
      A11y.Sessions.Create_Node
        (Session, Invalid_Provider'Unchecked_Access, Invalid_Id, Result);

      A11y.Sessions.Attach_Root (Session, Root_Id, Result);
      A11y.Sessions.Attach (Session, Root_Id, Flattened_Id, Result);
      A11y.Sessions.Attach (Session, Flattened_Id, Button_Id, Result);
      A11y.Sessions.Attach (Session, Root_Id, Hidden_Id, Result);
      A11y.Sessions.Attach (Session, Hidden_Id, Hidden_Button_Id, Result);
      A11y.Sessions.Attach
        (Session, Root_Id, Descendants_Only_Id, Result);
      A11y.Sessions.Attach
        (Session, Descendants_Only_Id, List_Item_Id, Result);
      A11y.Sessions.Attach (Session, Root_Id, Invalid_Id, Result);
      Invalid_Provider.Node_Role := A11y.Roles.Button;
      Invalid_Provider.Node_Capabilities :=
        A11y.Capabilities.Empty_Capability_Set;

      A11y.Sessions.Exposed_Children_Of
        (Session, Root_Id, Children, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Natural (Children.Length) = 2
         and then Children (1) = Button_Id
         and then Children (2) = List_Item_Id,
         "session exposes centrally projected children from provider metadata");

      Check
        (not Children.Contains (Invalid_Id),
         "session exposure projection hides invalid provider contracts");

      Parent := A11y.Sessions.Exposed_Parent_Of
        (Session, Button_Id, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Parent = Root_Id,
         "session exposes centrally projected parent from provider metadata");

      Parent := A11y.Sessions.Exposed_Parent_Of
        (Session, Hidden_Button_Id, Result);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then Parent = A11y.Node_Ids.No_Node,
         "session hides projected parents inside hidden subtrees");

      A11y.Sessions.Add_Relation
        (Session,
         Root_Id,
         A11y.Relations.Described_By,
         Hidden_Button_Id,
         Result);
      A11y.Sessions.Add_Relation
        (Session,
         Hidden_Button_Id,
         A11y.Relations.Described_By,
         Button_Id,
         Result);
      Targets := A11y.Sessions.Relation_Targets
        (Session, Root_Id, A11y.Relations.Described_By);
      Check
        (Targets.Is_Empty,
         "session hides relation targets inside hidden subtrees");
      Targets := A11y.Sessions.Relation_Targets
        (Session, Hidden_Button_Id, A11y.Relations.Described_By);
      Check
        (Targets.Is_Empty,
         "session hides relations whose source is not externally exposed");

      A11y.Resource_Limits.Set_Limit
        (Limits, A11y.Resource_Limits.Native_Array_Size, 1, Result);
      A11y.Sessions.Configure_Limits (Session, Limits, Result);
      A11y.Sessions.Exposed_Children_Of
        (Session, Root_Id, Children, Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit,
         "session exposure projection applies configured child bounds");
   end Run_Exposure_Projection_Tests;

   procedure Run_Provider_Registration_Tests is
      Session : A11y.Sessions.Semantic_Session;
      Valid_Provider : aliased Test_Node_Provider :=
        (Node_Role => A11y.Roles.Button,
         Node_Capabilities => A11y.Capabilities.With_Capability
           (A11y.Capabilities.Empty_Capability_Set,
            A11y.Capabilities.Action),
         others => <>);
      Invalid_Provider : aliased Test_Node_Provider :=
        (Node_Role => A11y.Roles.Button,
         others => <>);
      Raising_Provider : aliased Test_Node_Provider :=
        (Raise_On_Query => True,
         others => <>);
      Node : A11y.Node_Ids.Node_Id;
      Result : A11y.Results.Result;
      Snapshot : A11y.Registry.Entry_Snapshot;
   begin
      A11y.Sessions.Create_Node
        (Session, Valid_Provider'Unchecked_Access, Node, Result);
      A11y.Sessions.Registry_Snapshot (Session, Node, Snapshot, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Capabilities (A11y.Capabilities.Action)
         and then A11y.Sessions.Pending_Event_Count (Session) = 1,
         "session validates providers and records immutable capabilities");

      A11y.Sessions.Create_Node
        (Session, Invalid_Provider'Unchecked_Access, Node, Result);
      Check
        (Result.Status = A11y.Results.Unsupported_Capability
         and then Node = A11y.Node_Ids.No_Node
         and then A11y.Sessions.Pending_Event_Count (Session) = 1,
         "session rejects invalid provider contracts before registration");

      A11y.Sessions.Create_Node
        (Session, Raising_Provider'Unchecked_Access, Node, Result);
      Check
        (Result.Status = A11y.Results.Internal_Error
         and then Node = A11y.Node_Ids.No_Node
         and then A11y.Sessions.Pending_Event_Count (Session) = 1,
         "session contains provider exceptions during contract validation");
   end Run_Provider_Registration_Tests;

   procedure Run is
   begin
      Run_Exposure_Projection_Tests;
      Run_Provider_Registration_Tests;
   end Run;
end A11y_Session_Projection_Tests;
