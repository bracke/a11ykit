with A11y.Node_Ids;
with A11y.Relations;
with A11y.Relations.Classification;
with A11y.Resource_Limits;
with A11y.Results;

with A11ykit_Test_Support;

package body A11y_Relation_Graph_Tests is
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Relations.Relation_Kind;
   use type A11y.Results.Status_Code;

   procedure Check (Condition : Boolean; Message : String)
      renames A11ykit_Test_Support.Check;

   type Test_Relation_Provider is new A11y.Relations.Relation_Provider
   with record
      Targets : A11y.Relations.Target_Vectors.Vector;
      Raise_On_Query : Boolean := False;
   end record;

   overriding function Relation_Targets
     (Self : Test_Relation_Provider;
      Kind : A11y.Relations.Relation_Kind)
      return A11y.Relations.Target_Vectors.Vector;

   overriding function Relation_Targets
     (Self : Test_Relation_Provider;
      Kind : A11y.Relations.Relation_Kind)
      return A11y.Relations.Target_Vectors.Vector
   is
      pragma Unreferenced (Kind);
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      return Self.Targets;
   end Relation_Targets;

   procedure Run is
      Graph : A11y.Relations.Relation_Graph;
      Field : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (20);
      Label : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (21);
      Error : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (22);
      Help : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (23);
      Result : A11y.Results.Result;
      Targets : A11y.Relations.Target_Vectors.Vector;
      Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
   begin
      Check
        (A11y.Relations.Stable_Name (A11y.Relations.Labelled_By)
         = "labelled-by"
         and then A11y.Relations.Metadata
           (A11y.Relations.Labelled_By).Inverse = A11y.Relations.Label_For
         and then A11y.Relations.Inverse (A11y.Relations.Error_Message)
           = A11y.Relations.Error_For,
         "relation framework exposes stable relation metadata");
      Check
        (A11y.Relations.Classification.Canonical_Inverse
           (A11y.Relations.Labelled_By) = A11y.Relations.Label_For
         and then A11y.Relations.Classification.Is_Canonical_Pair
           (A11y.Relations.Described_By,
            A11y.Relations.Description_For)
         and then A11y.Relations.Classification.Is_Self_Inverse
           (A11y.Relations.Member_Of)
         and then not A11y.Relations.Classification.Is_Self_Inverse
           (A11y.Relations.Embeds)
         and then A11y.Relations.Classification.Is_Label_Relation
           (A11y.Relations.Label_For)
         and then A11y.Relations.Classification.Is_Description_Relation
           (A11y.Relations.Error_Message)
         and then A11y.Relations.Classification.Is_Control_Relation
           (A11y.Relations.Active_Descendant)
         and then A11y.Relations.Classification.Allows_Cycles
           (A11y.Relations.Flows_To)
         and then not A11y.Relations.Classification.Allows_Cycles
           (A11y.Relations.Labelled_By),
         "relation classification exposes inverse and cycle policy");

      Check
        (A11y.Relations.Capacity (Graph)
         = A11y.Relations.Max_Relation_Targets,
         "relation graph exposes default target capacity");
      A11y.Resource_Limits.Set_Limit
        (Limits, A11y.Resource_Limits.Relation_Targets_Returned, 1, Result);
      Check
        (A11y.Results.Succeeded (Result),
         "relation graph fixture sets target capacity limit");
      A11y.Relations.Configure_Limits (Graph, Limits, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then A11y.Relations.Capacity (Graph) = 1,
         "relation graph applies configured target capacity");

      A11y.Relations.Add
        (Graph, Field, A11y.Relations.Labelled_By, Label, Result);
      Check
        (A11y.Results.Succeeded (Result),
         "relation graph accepts a valid relation");
      Targets := A11y.Relations.Targets
        (Graph, Field, A11y.Relations.Labelled_By);
      Check
        (Natural (Targets.Length) = 1 and then Targets.First_Element = Label,
         "relation graph stores canonical targets");
      Targets := A11y.Relations.Targets
        (Graph, Label, A11y.Relations.Label_For);
      Check
        (Natural (Targets.Length) = 1 and then Targets.First_Element = Field,
         "relation graph derives inverse targets");
      Check
        (not A11y.Relations.Has_Cycle (Graph, A11y.Relations.Labelled_By)
         and then not A11y.Relations.Has_Any_Cycle (Graph),
         "relation graph does not treat inverse pairs as same-kind cycles");

      A11y.Relations.Add
        (Graph, Field, A11y.Relations.Member_Of, Label, Result);
      Check
        (A11y.Results.Succeeded (Result),
         "relation graph accepts first diagnostic cycle edge");
      A11y.Relations.Add
        (Graph, Label, A11y.Relations.Member_Of, Field, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then A11y.Relations.Has_Cycle (Graph, A11y.Relations.Member_Of)
         and then A11y.Relations.Has_Any_Cycle (Graph),
         "relation graph diagnoses allowed same-kind relation cycles");
      A11y.Relations.Remove
        (Graph, Label, A11y.Relations.Member_Of, Field, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then not A11y.Relations.Has_Cycle
           (Graph, A11y.Relations.Member_Of),
         "relation graph cycle diagnostics update after relation removal");

      declare
         Provider : Test_Relation_Provider;
         Provider_Result : A11y.Results.Result;
         Provider_Targets : A11y.Relations.Target_Vectors.Vector;
         Truncated : Boolean;
      begin
         Provider.Targets.Append (Label);
         Provider_Targets :=
           A11y.Relations.Relation_Targets_Safely
             (Provider,
              A11y.Relations.Labelled_By,
              Provider_Result,
              Truncated);
         Check
           (A11y.Results.Succeeded (Provider_Result)
            and then not Truncated
            and then Natural (Provider_Targets.Length) = 1
            and then Provider_Targets.First_Element = Label,
            "relation provider safely returns bounded relation targets");

         Provider.Targets.Append (Help);
         Provider_Targets :=
           A11y.Relations.Relation_Targets_Safely
             (Provider,
              A11y.Relations.Labelled_By,
              Limits,
              Provider_Result,
              Truncated);
         Check
           (Provider_Result.Status = A11y.Results.Resource_Limit
            and then Truncated
            and then Provider_Targets.Is_Empty,
            "relation provider enforces returned-target resource limits");

         Provider.Targets.Clear;
         Provider.Targets.Append (A11y.Node_Ids.No_Node);
         Provider_Targets :=
           A11y.Relations.Relation_Targets_Safely
             (Provider,
              A11y.Relations.Labelled_By,
              Provider_Result,
              Truncated);
         Check
           (Provider_Result.Status = A11y.Results.Node_Unavailable
            and then Provider_Targets.Is_Empty,
            "relation provider rejects invalid target identities");

         Provider.Targets.Clear;
         Provider.Targets.Append (Label);
         Provider.Targets.Append (Label);
         Provider_Targets :=
           A11y.Relations.Relation_Targets_Safely
             (Provider,
              A11y.Relations.Labelled_By,
              Provider_Result,
              Truncated);
         Check
           (Provider_Result.Status = A11y.Results.Invalid_State
            and then Provider_Targets.Is_Empty,
            "relation provider rejects duplicate target identities");

         Provider.Raise_On_Query := True;
         Provider_Targets :=
           A11y.Relations.Relation_Targets_Safely
             (Provider,
              A11y.Relations.Labelled_By,
              Provider_Result,
              Truncated);
         Check
           (Provider_Result.Status = A11y.Results.Internal_Error
            and then not Truncated
            and then Provider_Targets.Is_Empty,
            "relation provider contains query exceptions as empty targets");
      end;

      A11y.Relations.Add
        (Graph, Field, A11y.Relations.Labelled_By, Help, Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit,
         "relation graph rejects target overflow without mutation");
      Targets := A11y.Relations.Targets
        (Graph, Field, A11y.Relations.Labelled_By);
      Check
        (Natural (Targets.Length) = 1 and then Targets.First_Element = Label,
         "relation graph preserves canonical targets after overflow");

      A11y.Relations.Add
        (Graph, Field, A11y.Relations.Error_Message, Error, Result);
      Targets := A11y.Relations.Sources_Targeting (Graph, Error);
      Check
        (Natural (Targets.Length) = 1 and then Targets.First_Element = Field,
         "relation graph reports sources affected by target removal");
      Targets := A11y.Relations.Sources_Targeting
        (Graph, Error, A11y.Relations.Error_Message);
      Check
        (Natural (Targets.Length) = 1 and then Targets.First_Element = Field,
         "relation graph reports sources affected by target removal by kind");
      Targets := A11y.Relations.Sources_Targeting
        (Graph, Error, A11y.Relations.Labelled_By);
      Check
        (Targets.Is_Empty,
         "relation graph excludes unrelated relation kinds from target-source lookup");
      Targets := A11y.Relations.Sources_Targeting
        (Graph, A11y.Node_Ids.No_Node);
      Check
        (Targets.Is_Empty,
         "relation graph rejects affected-source queries for invalid nodes");
      A11y.Relations.Remove_Node (Graph, Error);
      Targets := A11y.Relations.Targets
        (Graph, Field, A11y.Relations.Error_Message);
      Check
        (Targets.Is_Empty,
         "relation graph removes dangling targets when a node disappears");

      A11y.Relations.Remove
        (Graph, Field, A11y.Relations.Labelled_By, Label, Result);
      Targets := A11y.Relations.Targets
        (Graph, Label, A11y.Relations.Label_For);
      Check
        (Targets.Is_Empty,
         "relation graph removes inverse targets coherently");

      A11y.Relations.Set_Capacity (Graph, 0, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument,
         "relation graph rejects invalid target capacity");
   end Run;
end A11y_Relation_Graph_Tests;
