with A11y;
with A11y.Node_Ids;
with A11y.Node_Keys;
with A11y.Nodes;
with A11y.Registry;
with A11y.Resource_Limits;
with A11y.Results;

with A11ykit_Test_Support;

package body A11y_Registry_Tests is
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Results.Status_Code;

   procedure Check (Condition : Boolean; Message : String)
      renames A11ykit_Test_Support.Check;

   procedure Run is
   begin
      declare
         Max_Id : constant A11y.Node_Ids.Node_Id :=
           A11y.Node_Ids.From_Natural (A11y.Node_Ids.Max_Node_Ids);
         Out_Of_Range : constant A11y.Node_Ids.Node_Id :=
           A11y.Node_Ids.From_Natural (A11y.Node_Ids.Max_Node_Ids + 1);
      begin
         Check
           (not A11y.Node_Ids.Is_Valid (A11y.Node_Ids.No_Node)
            and then A11y.Node_Ids.Is_Valid (Max_Id)
            and then not A11y.Node_Ids.Is_Valid (Out_Of_Range),
            "Node_Id validity is bounded by the documented registry capacity");
         Check
           (A11y.Node_Ids.Image (A11y.Node_Ids.No_Node) = "none"
            and then A11y.Node_Ids.Image (Max_Id) = "65536",
            "Node_Id images are stable trimmed diagnostic strings");
         Check
           (A11y.Event_Sequence_Image (A11y.No_Event) = "0"
            and then A11y.Event_Sequence_Image (42) = "42",
            "event sequence images are stable trimmed diagnostic strings");
      end;

      declare
         Registry : A11y.Registry.Node_Registry;
         First_Id : A11y.Node_Ids.Node_Id;
         Second_Id : A11y.Node_Ids.Node_Id;
         Result : A11y.Results.Result;
         Provider : A11y.Registry.Node_Access;
         State : A11y.Nodes.Lifecycle_State;
         Snapshot : A11y.Registry.Entry_Snapshot;
         Pin : A11y.Registry.Pin;
         Second_Pin : A11y.Registry.Pin;
         Limits : A11y.Resource_Limits.Resource_Limit_Config :=
           A11y.Resource_Limits.Default_Config;
      begin
         Registry.Allocate (First_Id);
         Registry.Allocate (Second_Id);
         Check
           (A11y.Node_Ids.Is_Valid (First_Id),
            "registry allocates a valid Node_Id");
         Check
           (First_Id /= Second_Id,
            "registry does not reuse live identities");

         Registry.Register (First_Id, null, Result);
         Check
           (A11y.Results.Succeeded (Result),
            "registry accepts a fresh node");
         Registry.Set_Lifecycle (First_Id, A11y.Nodes.Active, Result);
         Check
           (A11y.Results.Succeeded (Result),
            "registry records lifecycle changes");
         Registry.Set_Lifecycle (First_Id, A11y.Nodes.Created, Result);
         Check
           (Result.Status = A11y.Results.Invalid_State,
            "registry rejects lifecycle rollback transitions");

         Registry.Pin_Node (First_Id, Pin, Result);
         Check (A11y.Results.Succeeded (Result), "registry pins a live node");
         Registry.Snapshot (First_Id, Snapshot, Result);
         Check
           (Snapshot.Pinned = 1
            and then Snapshot.Pin_Limit = Natural
              (A11y.Resource_Limits.Value
                 (A11y.Resource_Limits.Default_Config,
                  A11y.Resource_Limits.Outstanding_Callbacks)),
            "registry reports outstanding callback pins and configured limit");

         A11y.Resource_Limits.Set_Limit
           (Limits, A11y.Resource_Limits.Outstanding_Callbacks, 1, Result);
         Registry.Configure_Limits (Limits, Result);
         Check
           (A11y.Results.Succeeded (Result),
            "registry accepts callback pin resource limits");
         Registry.Pin_Node (First_Id, Second_Pin, Result);
         Check
           (Result.Status = A11y.Results.Resource_Limit,
            "registry rejects callback pin overflow without mutation");
         Registry.Snapshot (First_Id, Snapshot, Result);
         Check
           (Snapshot.Pinned = 1,
            "registry preserves pin count after callback pin overflow");
         Registry.Unpin_Node (Pin);

         A11y.Resource_Limits.Set_Limit
           (Limits, A11y.Resource_Limits.Outstanding_Callbacks, 2, Result);
         Registry.Configure_Limits (Limits, Result);
         Registry.Pin_Node (First_Id, Pin, Result);
         Registry.Pin_Node (First_Id, Second_Pin, Result);
         A11y.Resource_Limits.Set_Limit
           (Limits, A11y.Resource_Limits.Outstanding_Callbacks, 1, Result);
         Registry.Configure_Limits (Limits, Result);
         Check
           (Result.Status = A11y.Results.Invalid_State,
            "registry rejects shrinking callback pins below outstanding count");
         Registry.Unpin_Node (Second_Pin);
         Registry.Unpin_Node (Pin);

         Limits.Limits (A11y.Resource_Limits.Outstanding_Callbacks) := 0;
         Registry.Configure_Limits (Limits, Result);
         Check
           (Result.Status = A11y.Results.Invalid_Argument,
            "registry rejects invalid callback pin resource limits");

         Registry.Remove (First_Id, Result);
         Check
           (A11y.Results.Succeeded (Result),
            "registry removes a node safely");
         Registry.Set_Lifecycle (First_Id, A11y.Nodes.Active, Result);
         Check
           (Result.Status = A11y.Results.Invalid_State,
            "registry rejects tombstone resurrection transitions");
         Registry.Lookup (First_Id, Provider, State, Result);
         Check
           (Result.Status = A11y.Results.Node_Unavailable,
            "stale registry lookup cannot resolve removed provider state");

         Registry.Register (First_Id, null, Result);
         Check
           (Result.Status = A11y.Results.Invalid_State,
            "registry never reuses tombstoned identities");

         Registry.Register (Second_Id, null, Result);
         Check
           (A11y.Results.Succeeded (Result),
            "registry accepts the next fresh allocated identity");
         Registry.Set_Parent (Second_Id, Second_Id, Result);
         Check
           (Result.Status = A11y.Results.Invalid_Argument,
            "registry rejects self-parent attachment metadata");
         Registry.Set_Parent
           (Second_Id, A11y.Node_Ids.From_Natural (99_999), Result);
         Check
           (Result.Status = A11y.Results.Node_Unavailable,
            "registry rejects unavailable parent attachment metadata");
      end;

      declare
         Keys : A11y.Node_Keys.Key_Registry;
         First : constant A11y.Node_Ids.Node_Id :=
           A11y.Node_Ids.From_Natural (10);
         Second : constant A11y.Node_Ids.Node_Id :=
           A11y.Node_Ids.From_Natural (11);
         Result : A11y.Results.Result;
         Limits : A11y.Resource_Limits.Resource_Limit_Config :=
           A11y.Resource_Limits.Default_Config;
      begin
         Check
           (A11y.Node_Keys.Capacity (Keys)
            = Natural
              (A11y.Resource_Limits.Value
                 (A11y.Resource_Limits.Default_Config,
                  A11y.Resource_Limits.Virtual_Node_Realization)),
            "node key registry uses the shared virtual-node realization bound");
         A11y.Node_Keys.Bind (Keys, "row:10", First, Result);
         Check
           (A11y.Results.Succeeded (Result)
            and then A11y.Node_Keys.Lookup (Keys, "row:10") = First
            and then A11y.Node_Keys.Count (Keys) = 1,
            "node key registry resolves application keys to stable node ids");
         A11y.Node_Keys.Bind (Keys, "row:10", First, Result);
         Check
           (A11y.Results.Succeeded (Result)
            and then A11y.Node_Keys.Count (Keys) = 1,
            "node key registry treats duplicate identical bindings as idempotent");
         A11y.Node_Keys.Bind (Keys, "row:10", Second, Result);
         Check
           (Result.Status = A11y.Results.Invalid_State
            and then A11y.Node_Keys.Lookup (Keys, "row:10") = First,
            "node key registry rejects key collisions without mutation");
         A11y.Node_Keys.Bind (Keys, "row:11", First, Result);
         Check
           (Result.Status = A11y.Results.Invalid_State
            and then A11y.Node_Keys.Count (Keys) = 1,
            "node key registry rejects node collisions without mutation");
         A11y.Node_Keys.Bind
           (Keys, "", A11y.Node_Ids.No_Node, Result);
         Check
           (Result.Status = A11y.Results.Invalid_Argument,
            "node key registry rejects invalid bindings");

         A11y.Resource_Limits.Set_Limit
           (Limits,
            A11y.Resource_Limits.Virtual_Node_Realization,
            1,
            Result);
         A11y.Node_Keys.Configure_Limits (Keys, Limits, Result);
         Check
           (A11y.Results.Succeeded (Result)
            and then A11y.Node_Keys.Capacity (Keys) = 1,
            "node key registry applies configured realization bounds");
         A11y.Node_Keys.Bind (Keys, "row:11", Second, Result);
         Check
           (Result.Status = A11y.Results.Resource_Limit
            and then A11y.Node_Keys.Lookup (Keys, "row:11")
              = A11y.Node_Ids.No_Node,
            "node key registry bounds externally realized key mappings");
         A11y.Resource_Limits.Set_Limit
           (Limits,
            A11y.Resource_Limits.Virtual_Node_Realization,
            2,
            Result);
         A11y.Node_Keys.Configure_Limits (Keys, Limits, Result);
         A11y.Node_Keys.Bind (Keys, "row:11", Second, Result);
         Check
           (A11y.Results.Succeeded (Result)
            and then A11y.Node_Keys.Count (Keys) = 2,
            "node key registry grows configured realization bounds");
         A11y.Resource_Limits.Set_Limit
           (Limits,
            A11y.Resource_Limits.Virtual_Node_Realization,
            1,
            Result);
         A11y.Node_Keys.Configure_Limits (Keys, Limits, Result);
         Check
           (Result.Status = A11y.Results.Invalid_State
            and then A11y.Node_Keys.Count (Keys) = 2,
            "node key registry rejects shrinking below realized mappings");
         A11y.Node_Keys.Unbind_Key (Keys, "row:10", Result);
         Check
           (A11y.Results.Succeeded (Result)
            and then A11y.Node_Keys.Lookup (Keys, "row:10")
              = A11y.Node_Ids.No_Node,
            "node key registry unbinds by application key");
         A11y.Node_Keys.Unbind_Node (Keys, Second, Result);
         Check
           (A11y.Results.Succeeded (Result)
            and then A11y.Node_Keys.Count (Keys) = 0,
            "node key registry unbinds by node identity");
      end;
   end Run;
end A11y_Registry_Tests;
