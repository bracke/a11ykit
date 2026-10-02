with A11y.Geometry;

with A11ykit_Test_Support;

package body A11y_Geometry_Tests is
   use type A11y.Geometry.Coordinate;
   use type A11y.Geometry.Length;
   use type A11y.Geometry.Rectangle;
   use type A11y.Geometry.Visibility;

   procedure Check (Condition : Boolean; Message : String)
      renames A11ykit_Test_Support.Check;

   procedure Run is
      Viewport : constant A11y.Geometry.Rectangle :=
        (Origin => (X => -100, Y => -50),
         Extent => (Width => 300, Height => 200));
      Inside : constant A11y.Geometry.Rectangle :=
        (Origin => (X => -10, Y => 0),
         Extent => (Width => 40, Height => 40));
      Partial : constant A11y.Geometry.Rectangle :=
        (Origin => (X => 150, Y => 100),
         Extent => (Width => 100, Height => 100));
      Outside : constant A11y.Geometry.Rectangle :=
        (Origin => (X => 500, Y => 500),
         Extent => (Width => 10, Height => 10));
      Huge : constant A11y.Geometry.Rectangle :=
        (Origin => (X => A11y.Geometry.Coordinate'Last - 1, Y => 0),
         Extent => (Width => 10, Height => 1));
      Area : A11y.Geometry.Region (3);
      Clipped : A11y.Geometry.Region (3);
      Union : A11y.Geometry.Rectangle;
      Clip : A11y.Geometry.Rectangle;
      Added : Boolean;
   begin
      Clip := A11y.Geometry.Intersection (Viewport, Partial);
      Check
        (A11y.Geometry.Right (Huge) = A11y.Geometry.Coordinate'Last
         and then A11y.Geometry.Bottom (Huge) = 1,
         "geometry framework saturates rectangle edges");
      Check
        (A11y.Geometry.Contains (Viewport, Inside)
         and then A11y.Geometry.Contains
           (Viewport, A11y.Geometry.Point'(X => -100, Y => -50))
         and then not A11y.Geometry.Contains
           (Viewport, A11y.Geometry.Point'(X => 200, Y => 150)),
         "geometry framework handles logical desktop containment");
      Check
        (A11y.Geometry.Intersects (Viewport, Partial)
         and then not A11y.Geometry.Intersects (Viewport, Outside)
         and then Clip.Origin.X = 150
         and then Clip.Origin.Y = 100
         and then Clip.Extent.Width = 50
         and then Clip.Extent.Height = 50,
         "geometry framework computes clipped intersections");
      Check
        (A11y.Geometry.Classify_Visibility (Viewport, Inside)
           = A11y.Geometry.Fully_Visible
         and then A11y.Geometry.Classify_Visibility (Viewport, Partial)
           = A11y.Geometry.Partially_Visible
         and then A11y.Geometry.Classify_Visibility (Viewport, Outside)
           = A11y.Geometry.Fully_Offscreen
         and then A11y.Geometry.Classify_Visibility
           (Viewport, A11y.Geometry.Empty_Rectangle)
             = A11y.Geometry.Fully_Offscreen,
         "geometry framework classifies semantic visibility centrally");
      A11y.Geometry.Add_Rectangle
        (Area, A11y.Geometry.Empty_Rectangle, Added);
      Check
        (not Added and then A11y.Geometry.Rectangle_Count (Area) = 0,
         "geometry framework omits empty region rectangles");
      A11y.Geometry.Add_Rectangle (Area, Inside, Added);
      A11y.Geometry.Add_Rectangle (Area, Partial, Added);
      A11y.Geometry.Add_Rectangle (Area, Outside, Added);
      A11y.Geometry.Add_Rectangle (Area, Viewport, Added);
      Union := A11y.Geometry.Bounds (Area);
      Check
        (not Added
         and then A11y.Geometry.Rectangle_Count (Area) = 3
         and then A11y.Geometry.Contains
           (Area, A11y.Geometry.Point'(X => 151, Y => 101))
         and then not A11y.Geometry.Contains
           (Area, A11y.Geometry.Point'(X => 300, Y => 300))
         and then A11y.Geometry.Intersects (Area, Viewport)
         and then Union.Origin.X = -10
         and then Union.Origin.Y = 0
         and then Union.Extent.Width = 520
         and then Union.Extent.Height = 510,
         "geometry framework stores bounded logical desktop regions");
      Clipped := A11y.Geometry.Clip (Area, Viewport);
      Check
        (A11y.Geometry.Rectangle_Count (Clipped) = 2
         and then A11y.Geometry.Rectangle_At (Clipped, 1) = Inside
         and then A11y.Geometry.Rectangle_At (Clipped, 2) = Clip
         and then A11y.Geometry.Rectangle_At (Clipped, 3)
           = A11y.Geometry.Empty_Rectangle,
         "geometry framework clips regions without native policy");
      A11y.Geometry.Clear (Area);
      Check
        (A11y.Geometry.Rectangle_Count (Area) = 0
         and then A11y.Geometry.Bounds (Area)
           = A11y.Geometry.Empty_Rectangle,
         "geometry framework clears regions deterministically");
   end Run;
end A11y_Geometry_Tests;
