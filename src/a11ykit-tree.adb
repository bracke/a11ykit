with Ada.Containers.Generic_Array_Sort;
with Ada.Containers.Hashed_Maps;
with Ada.Strings.Unbounded;
with Ada.Unchecked_Deallocation;

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
      if Result.Nodes.Is_Empty then
         return Result;
      end if;

      declare
         subtype Node_Range is Positive range Result.Nodes.First_Index .. Result.Nodes.Last_Index;
         type Order_Array is array (Positive range <>) of Positive;
         type Order_Access is access Order_Array;
         procedure Free is new Ada.Unchecked_Deallocation (Order_Array, Order_Access);

         function Area_Of (Index : Positive) return Natural is (Area (Result.Nodes (Index).Bounds));

         --  By area, then input order: the order the tightest-container rule
         --  prefers its candidates in.
         function Before (Left, Right : Positive) return Boolean is
           (Area_Of (Left) < Area_Of (Right)
            or else (Area_Of (Left) = Area_Of (Right) and then Left < Right));
         procedure Sort is new Ada.Containers.Generic_Array_Sort
           (Index_Type => Positive, Element_Type => Positive, Array_Type => Order_Array, "<" => Before);

         use type Ada.Containers.Hash_Type;
         function Hash (Box : Rectangle) return Ada.Containers.Hash_Type is
           (Ada.Containers.Hash_Type'Mod (Box.X) * 31 + Ada.Containers.Hash_Type'Mod (Box.Y) * 131
            + Ada.Containers.Hash_Type'Mod (Box.Width) * 1031 + Ada.Containers.Hash_Type'Mod (Box.Height));
         --  The first node drawn with each rectangle.
         package First_Maps is new Ada.Containers.Hashed_Maps
           (Key_Type => Rectangle, Element_Type => Positive, Hash => Hash, Equivalent_Keys => "=");
         First_With : First_Maps.Map;

         --  On the heap: a frame can hold more nodes than a small stack has
         --  room for.
         Order : Order_Access := new Order_Array (1 .. Natural (Result.Nodes.Length));
         --  For each place in Order, the first place past it of a larger
         --  area: a grid's many cells of one size are stepped over at once,
         --  not tried one by one as each other's container.
         Larger : Order_Access := new Order_Array (1 .. Natural (Result.Nodes.Length) + 1);

         --  The old search, kept for a node of no area: such nodes can
         --  enclose one another without being the same rectangle.
         function Searched_Parent (Child : Positive) return Natural is
            Best_Parent : Natural := 0;
            Best_Area   : Natural := 0;
         begin
            for Cand in Node_Range loop
               if May_Parent (Result.Nodes, Child, Cand) then
                  if Best_Parent = 0
                    or else Area_Of (Cand) < Best_Area
                    or else (Area_Of (Cand) = Best_Area and then Cand < Best_Parent)
                  then
                     Best_Parent := Cand;
                     Best_Area := Area_Of (Cand);
                  end if;
               end if;
            end loop;
            return Best_Parent;
         end Searched_Parent;

         --  The tightest enclosing candidate: smallest area, ties to the
         --  lowest index. A candidate of the child's own (non-zero) area
         --  encloses it only as the very same rectangle, drawn earlier;
         --  otherwise the first candidate in Order past the child's area
         --  that encloses it is the smallest, and of those the earliest.
         function Parent_Of (Child : Positive; Position : Positive) return Natural is
            Box  : constant Rectangle := Result.Nodes (Child).Bounds;
            Same : constant First_Maps.Cursor := First_With.Find (Box);
         begin
            if Area (Box) = 0 then
               return Searched_Parent (Child);
            end if;
            if First_Maps.Has_Element (Same) and then First_Maps.Element (Same) < Child then
               return First_Maps.Element (Same);
            end if;
            for Next in Larger (Position) .. Order'Last loop
               if Encloses (Result.Nodes (Order (Next)).Bounds, Box) then
                  return Order (Next);
               end if;
            end loop;
            return 0;
         end Parent_Of;
      begin
         for Index in Node_Range loop
            Order (Index - Node_Range'First + 1) := Index;
            if not First_With.Contains (Result.Nodes (Index).Bounds) then
               First_With.Insert (Result.Nodes (Index).Bounds, Index);
            end if;
         end loop;
         Sort (Order.all);
         Larger (Larger'Last) := Larger'Last;
         for Position in reverse Order'Range loop
            Larger (Position) :=
              (if Position = Order'Last then Larger'Last
               elsif Area_Of (Order (Position + 1)) > Area_Of (Order (Position)) then Position + 1
               else Larger (Position + 1));
         end loop;
         for Position in Order'Range loop
            declare
               Child   : constant Positive := Order (Position);
               Updated : Node := Result.Nodes (Child);
            begin
               Updated.Parent := Parent_Of (Child, Position);
               Result.Nodes.Replace_Element (Child, Updated);
            end;
         end loop;
         Free (Order);
         Free (Larger);
      exception
         when others =>
            Free (Order);
            Free (Larger);
            raise;
      end;

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

   function Valid_UTF8 (Text : String) return String is
      Replacement : constant String :=
        Character'Val (16#EF#) & Character'Val (16#BF#) & Character'Val (16#BD#);
      Result : Ada.Strings.Unbounded.Unbounded_String;
      I      : Natural := Text'First;

      function Byte (Index : Positive) return Natural is (Character'Pos (Text (Index)));

      --  The length of the well-formed sequence starting at I (RFC 3629: no
      --  overlong forms, no surrogates, nothing past U+10FFFF), or 0.
      function Sequence_Length return Natural is
         Lead : constant Natural := Byte (I);
         Size : constant Natural :=
           (if Lead < 16#80# then 1
            elsif Lead in 16#C2# .. 16#DF# then 2
            elsif Lead in 16#E0# .. 16#EF# then 3
            elsif Lead in 16#F0# .. 16#F4# then 4
            else 0);
      begin
         if Size <= 1 then
            return Size;
         elsif I + Size - 1 > Text'Last then
            return 0;
         end if;
         for K in I + 1 .. I + Size - 1 loop
            if Byte (K) not in 16#80# .. 16#BF# then
               return 0;
            end if;
         end loop;
         --  The second byte's narrower ranges after these leads.
         if (Lead = 16#E0# and then Byte (I + 1) < 16#A0#)
           or else (Lead = 16#ED# and then Byte (I + 1) > 16#9F#)
           or else (Lead = 16#F0# and then Byte (I + 1) < 16#90#)
           or else (Lead = 16#F4# and then Byte (I + 1) > 16#8F#)
         then
            return 0;
         end if;
         return Size;
      end Sequence_Length;
   begin
      if (for all C of Text => C < Character'Val (16#80#)) then
         return Text;
      end if;
      while I <= Text'Last loop
         declare
            Size : constant Natural := Sequence_Length;
         begin
            if Size = 0 then
               Ada.Strings.Unbounded.Append (Result, Replacement);
               I := I + 1;
            else
               Ada.Strings.Unbounded.Append (Result, Text (I .. I + Size - 1));
               I := I + Size;
            end if;
         end;
      end loop;
      return Ada.Strings.Unbounded.To_String (Result);
   end Valid_UTF8;

   function With_Valid_Text (Tree : Accessibility_Tree) return Accessibility_Tree is
      Result : Accessibility_Tree := Tree;
   begin
      for Item of Result.Nodes loop
         Item.Name := Ada.Strings.Unbounded.To_Unbounded_String
           (Valid_UTF8 (Ada.Strings.Unbounded.To_String (Item.Name)));
         Item.Description := Ada.Strings.Unbounded.To_Unbounded_String
           (Valid_UTF8 (Ada.Strings.Unbounded.To_String (Item.Description)));
      end loop;
      return Result;
   end With_Valid_Text;

end A11ykit.Tree;
