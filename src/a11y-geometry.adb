package body A11y.Geometry is
   pragma SPARK_Mode (On);

   function Saturating_Add
     (Left  : Coordinate;
      Width : Length)
     return Coordinate
     with
       Post =>
         Saturating_Add'Result = Coordinate'Last
         or else Saturating_Add'Result >= Left
   is
      Extent : constant Coordinate := Coordinate (Width);
   begin
      if Extent > 0 and then Left > Coordinate'Last - Extent then
         return Coordinate'Last;
      end if;

      return Left + Extent;
   end Saturating_Add;

   function Saturating_Difference
     (High : Coordinate;
      Low  : Coordinate)
      return Length
     with
       Pre  => High >= Low,
       Post => Saturating_Difference'Result <= Length'Last
   is
   begin
      if High = Low then
         return 0;
      elsif Low >= 0 then
         if High - Low > Coordinate (Length'Last) then
            return Length'Last;
         end if;

         return Length (High - Low);
      elsif High > Coordinate (Length'Last) + Low then
         return Length'Last;
      end if;

      return Length (High - Low);
   end Saturating_Difference;

   function Is_Empty (Box : Rectangle) return Boolean is
     (Box.Extent.Width = 0 or else Box.Extent.Height = 0);

   function Right (Box : Rectangle) return Coordinate is
     (Saturating_Add (Box.Origin.X, Box.Extent.Width));

   function Bottom (Box : Rectangle) return Coordinate is
     (Saturating_Add (Box.Origin.Y, Box.Extent.Height));

   function Contains (Outer : Rectangle; Inner : Rectangle) return Boolean is
     (not Is_Empty (Outer)
      and then not Is_Empty (Inner)
      and then Inner.Origin.X >= Outer.Origin.X
      and then Inner.Origin.Y >= Outer.Origin.Y
      and then Right (Inner) <= Right (Outer)
      and then Bottom (Inner) <= Bottom (Outer));

   function Contains (Outer : Rectangle; P : Point) return Boolean is
     (not Is_Empty (Outer)
      and then P.X >= Outer.Origin.X
      and then P.Y >= Outer.Origin.Y
      and then P.X < Right (Outer)
      and then P.Y < Bottom (Outer));

   function Intersects (Left, Right : Rectangle) return Boolean is
     (not Is_Empty (Left)
      and then not Is_Empty (Right)
      and then Left.Origin.X < A11y.Geometry.Right (Right)
      and then Right.Origin.X < A11y.Geometry.Right (Left)
      and then Left.Origin.Y < A11y.Geometry.Bottom (Right)
      and then Right.Origin.Y < A11y.Geometry.Bottom (Left));

   function Intersection (Left, Right : Rectangle) return Rectangle is
   begin
      if not Intersects (Left, Right) then
         return Empty_Rectangle;
      end if;

      declare
         X1 : constant Coordinate := Coordinate'Max
           (Left.Origin.X, Right.Origin.X);
         Y1 : constant Coordinate := Coordinate'Max
           (Left.Origin.Y, Right.Origin.Y);
         X2 : constant Coordinate := Coordinate'Min
           (A11y.Geometry.Right (Left), A11y.Geometry.Right (Right));
         Y2 : constant Coordinate := Coordinate'Min
           (A11y.Geometry.Bottom (Left), A11y.Geometry.Bottom (Right));
      begin
         if X2 <= X1 or else Y2 <= Y1 then
            return Empty_Rectangle;
         end if;

         return
           (Origin => (X => X1, Y => Y1),
            Extent =>
              (Width  => Saturating_Difference (X2, X1),
               Height => Saturating_Difference (Y2, Y1)));
      end;
   end Intersection;

   function Classify_Visibility
     (Viewport : Rectangle;
      Bounds   : Rectangle)
      return Visibility
   is
   begin
      if not Intersects (Viewport, Bounds) then
         return Fully_Offscreen;
      elsif Contains (Viewport, Bounds) then
         return Fully_Visible;
      end if;

      return Partially_Visible;
   end Classify_Visibility;

   function Rectangle_Count (Area : Region) return Natural is
     (Area.Count);

   function Rectangle_At
     (Area  : Region;
      Index : Positive)
      return Rectangle
   is
   begin
      if Index > Area.Count then
         return Empty_Rectangle;
      end if;

      return Area.Rectangles (Index);
   end Rectangle_At;

   procedure Clear (Area : in out Region) is
   begin
      Area.Count := 0;
   end Clear;

   procedure Add_Rectangle
     (Area  : in out Region;
      Box   : Rectangle;
      Added : out Boolean)
   is
   begin
      if Is_Empty (Box) or else Area.Count >= Area.Capacity then
         Added := False;
         return;
      end if;

      Area.Count := Area.Count + 1;
      Area.Rectangles (Area.Count) := Box;
      Added := True;
   end Add_Rectangle;

   function Contains (Area : Region; P : Point) return Boolean is
   begin
      for Index in 1 .. Area.Count loop
         pragma Loop_Invariant (Area.Count <= Area.Capacity);
         pragma Loop_Invariant (Index <= Area.Capacity);
         if Contains (Area.Rectangles (Index), P) then
            return True;
         end if;
      end loop;

      return False;
   end Contains;

   function Intersects (Area : Region; Box : Rectangle) return Boolean is
   begin
      if Is_Empty (Box) then
         return False;
      end if;

      for Index in 1 .. Area.Count loop
         pragma Loop_Invariant (Area.Count <= Area.Capacity);
         pragma Loop_Invariant (Index <= Area.Capacity);
         if Intersects (Area.Rectangles (Index), Box) then
            return True;
         end if;
      end loop;

      return False;
   end Intersects;

   function Bounds (Area : Region) return Rectangle is
   begin
      if Area.Count = 0 then
         return Empty_Rectangle;
      end if;

      declare
         X1 : Coordinate := Area.Rectangles (1).Origin.X;
         Y1 : Coordinate := Area.Rectangles (1).Origin.Y;
         X2 : Coordinate := Right (Area.Rectangles (1));
         Y2 : Coordinate := Bottom (Area.Rectangles (1));
      begin
         for Index in 2 .. Area.Count loop
            pragma Loop_Invariant (Area.Count <= Area.Capacity);
            pragma Loop_Invariant (Index <= Area.Capacity);
            X1 := Coordinate'Min (X1, Area.Rectangles (Index).Origin.X);
            Y1 := Coordinate'Min (Y1, Area.Rectangles (Index).Origin.Y);
            X2 := Coordinate'Max (X2, Right (Area.Rectangles (Index)));
            Y2 := Coordinate'Max (Y2, Bottom (Area.Rectangles (Index)));
         end loop;

         return
           (Origin => (X => X1, Y => Y1),
            Extent =>
              (Width  => Saturating_Difference (X2, X1),
               Height => Saturating_Difference (Y2, Y1)));
      end;
   end Bounds;

   function Clip
     (Area     : Region;
      Viewport : Rectangle)
      return Region
   is
      Result : Region (Area.Capacity);
      Added  : Boolean;
   begin
      if Is_Empty (Viewport) then
         return Result;
      end if;

      for Index in 1 .. Area.Count loop
         pragma Loop_Invariant (Area.Count <= Area.Capacity);
         pragma Loop_Invariant (Index <= Area.Capacity);
         pragma Loop_Invariant (Result.Count <= Result.Capacity);
         Add_Rectangle
           (Result,
            Intersection (Area.Rectangles (Index), Viewport),
            Added);
      end loop;

      return Result;
   end Clip;

end A11y.Geometry;
