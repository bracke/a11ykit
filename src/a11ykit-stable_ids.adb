with Ada.Containers.Ordered_Sets;

with A11y.Trees;

package body A11ykit.Stable_Ids is

   use Ada.Strings.Unbounded;

   package Id_Sets is new Ada.Containers.Ordered_Sets (Positive);

   procedure Assign (State : in out Id_State; Tree : in out A11ykit.Tree.Accessibility_Tree) is
      Count      : constant Natural := Natural (Tree.Nodes.Length);
      Identities : array (1 .. Count) of Unbounded_String;
      Done       : array (1 .. Count) of Boolean := [others => False];
      Seen       : Id_Maps.Map;
      Taken      : Id_Sets.Set;
      Next_Free  : Positive := 2;
      Ids        : A11ykit.Tree.Index_Vectors.Vector;
      Fresh      : Id_Maps.Map;

      function Identity (Index : Positive; Depth : Natural := 0) return Unbounded_String is
      begin
         if not Done (Index) then
            declare
               Item : constant A11ykit.Tree.Node := Tree.Nodes (Index);
               Base : constant Unbounded_String :=
                 (if Item.Parent = 0 or else Depth > Count then Null_Unbounded_String
                  else Identity (Item.Parent, Depth + 1))
                 & "/" & A11ykit.Role'Image (Item.Node_Role) & ":" & Item.Name;
               Occurrence : constant Natural :=
                 (if Seen.Contains (Base) then Seen.Element (Base) + 1 else 1);
            begin
               Seen.Include (Base, Occurrence);
               Identities (Index) := Base & "#" & Natural'Image (Occurrence);
               Done (Index) := True;
            end;
         end if;
         return Identities (Index);
      end Identity;
   begin
      if Count = 0 then
         return;
      end if;
      for Index in 1 .. Count loop
         declare
            Ignored : constant Unbounded_String := Identity (Index);
         begin
            null;
         end;
      end loop;

      --  Ids of the last publication are not handed out afresh this time.
      for Id of State.Last_Ids loop
         Taken.Include (Id);
      end loop;
      Taken.Include (1);
      for Index in 1 .. Count loop
         declare
            Id : Positive := 1;
         begin
            if Index = 1 then
               Id := 1;
            elsif State.Id_Of_Identity.Contains (Identities (Index)) then
               Id := State.Id_Of_Identity.Element (Identities (Index));
            else
               while Taken.Contains (Next_Free) loop
                  Next_Free := Next_Free + 1;
               end loop;
               Id := Next_Free;
               Taken.Include (Id);
            end if;
            if Id > A11y.Trees.Max_Attached_Nodes then
               --  Out of ids: publish by position, as before stable ids.
               Tree.Ids.Clear;
               return;
            end if;
            Ids.Append (Id);
            Fresh.Include (Identities (Index), Id);
         end;
      end loop;
      Tree.Ids := Ids;
      State.Id_Of_Identity := Fresh;
      State.Last_Ids := Ids;
   end Assign;

end A11ykit.Stable_Ids;
