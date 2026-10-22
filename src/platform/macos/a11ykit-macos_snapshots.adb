with A11ykit.Compatibility;

with A11y.Geometry;
with A11y.Properties;
with A11y.Semantic_Snapshots;
with A11y.Trees;

package body A11ykit.MacOS_Snapshots is

   package Router renames A11y.MacOS_Backend.NSAccessibility_Request_Router;

   use type A11y.Properties.Property_Status;

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

      A11ykit.Compatibility.Attach_Parents_First (Tree, Snapshots.Properties.Tree, Check);
      if A11y.Results.Failed (Check) then
         Result := Check;
         return;
      end if;

      for Index in Tree.Nodes.First_Index .. Tree.Nodes.Last_Index loop
         declare
            Node : constant A11y.Node_Ids.Node_Id :=
              A11ykit.Compatibility.Node_Id_For_Index (Tree, Index);
         begin
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
      Snapshots.Hierarchy.Focused_Node :=
        (if A11y.Node_Ids.Is_Valid (A11ykit.Compatibility.Focused_Node (Tree))
         then A11ykit.Compatibility.Focused_Node (Tree)
         else Root);
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

end A11ykit.MacOS_Snapshots;
