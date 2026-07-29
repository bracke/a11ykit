package body A11ykit.Tree is

   function Area (Box : Rectangle) return Natural is
     (Box.Width * Box.Height);

   --  True when Outer fully encloses Inner.
   function Encloses (Outer : Rectangle; Inner : Rectangle) return Boolean is
     (Inner.X >= Outer.X
      and then Inner.Y >= Outer.Y
      and then Inner.X + Inner.Width <= Outer.X + Outer.Width
      and then Inner.Y + Inner.Height <= Outer.Y + Outer.Height);

   --  Whether J is a valid ancestor candidate for I: it encloses I and is
   --  strictly larger, or the same size but earlier -- a strict order, so a
   --  chain of parents can never form a cycle even among identical rectangles.
   function May_Parent
     (Nodes : Node_Vectors.Vector;
      Child : Positive;
      Cand  : Positive)
      return Boolean
   is
      Child_Box : constant Rectangle := Nodes (Child).Bounds;
      Cand_Box  : constant Rectangle := Nodes (Cand).Bounds;
   begin
      if Child = Cand or else not Encloses (Cand_Box, Child_Box) then
         return False;
      end if;
      return Area (Cand_Box) > Area (Child_Box)
        or else (Area (Cand_Box) = Area (Child_Box) and then Cand < Child);
   end May_Parent;

   function Build (Flat : Node_Vectors.Vector) return Accessibility_Tree is
      Result : Accessibility_Tree;
   begin
      Result.Nodes := Flat;

      for Child in Result.Nodes.First_Index .. Result.Nodes.Last_Index loop
         declare
            Best_Parent : Natural := 0;
            Best_Area   : Natural := 0;
         begin
            --  The tightest enclosing candidate: smallest area, ties to the
            --  lowest index.
            for Cand in Result.Nodes.First_Index .. Result.Nodes.Last_Index loop
               if May_Parent (Result.Nodes, Child, Cand) then
                  if Best_Parent = 0
                    or else Area (Result.Nodes (Cand).Bounds) < Best_Area
                    or else (Area (Result.Nodes (Cand).Bounds) = Best_Area
                             and then Cand < Best_Parent)
                  then
                     Best_Parent := Cand;
                     Best_Area := Area (Result.Nodes (Cand).Bounds);
                  end if;
               end if;
            end loop;

            declare
               Updated : Node := Result.Nodes (Child);
            begin
               Updated.Parent := Best_Parent;
               Result.Nodes.Replace_Element (Child, Updated);
            end;
         end;
      end loop;

      for Index in Result.Nodes.First_Index .. Result.Nodes.Last_Index loop
         if Result.Nodes (Index).Node_State.Focused then
            Result.Focused := Index;
            exit;
         end if;
      end loop;

      return Result;
   end Build;

   function Children_Of
     (Tree         : Accessibility_Tree;
      Parent_Index : Natural)
      return Index_Vectors.Vector
   is
      Result : Index_Vectors.Vector;
   begin
      for Index in Tree.Nodes.First_Index .. Tree.Nodes.Last_Index loop
         if Tree.Nodes (Index).Parent = Parent_Index then
            Result.Append (Index);
         end if;
      end loop;

      return Result;
   end Children_Of;

end A11ykit.Tree;
