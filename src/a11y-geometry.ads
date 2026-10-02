package A11y.Geometry is
   pragma SPARK_Mode (On);

   --  Logical desktop coordinates. Backends convert to native coordinate
   --  systems at their boundary.
   type Coordinate is new Long_Integer;
   type Length is new Natural;

   type Point is record
      X : Coordinate := 0;
      Y : Coordinate := 0;
   end record;

   type Size is record
      Width  : Length := 0;
      Height : Length := 0;
   end record;

   type Rectangle is record
      Origin : Point;
      Extent : Size;
   end record;

   type Visibility is
     (Fully_Offscreen,
      Partially_Visible,
      Fully_Visible);

   type Region (Capacity : Natural) is private;

   Empty_Rectangle : constant Rectangle :=
     (Origin => (X => 0, Y => 0), Extent => (Width => 0, Height => 0));

   function Contains (Outer : Rectangle; Inner : Rectangle) return Boolean
     with
       Global => null,
       Post =>
         (if Contains'Result then
            not Is_Empty (Outer) and then not Is_Empty (Inner));

   function Contains (Outer : Rectangle; P : Point) return Boolean
     with
       Global => null,
       Post => (if Contains'Result then not Is_Empty (Outer));

   function Is_Empty (Box : Rectangle) return Boolean
     with
       Global => null,
       Post =>
         Is_Empty'Result =
           (Box.Extent.Width = 0 or else Box.Extent.Height = 0);

   function Right (Box : Rectangle) return Coordinate
     with
       Global => null,
       Post =>
         Right'Result >= Box.Origin.X
         or else Right'Result = Coordinate'Last;

   function Bottom (Box : Rectangle) return Coordinate
     with
       Global => null,
       Post =>
         Bottom'Result >= Box.Origin.Y
         or else Bottom'Result = Coordinate'Last;

   function Intersects (Left, Right : Rectangle) return Boolean
     with
       Global => null,
       Post =>
         (if Intersects'Result then
            not Is_Empty (Left) and then not Is_Empty (Right));

   function Intersection (Left, Right : Rectangle) return Rectangle
     with
       Global => null,
       Post =>
         (if not Intersects (Left, Right) then
            Is_Empty (Intersection'Result));

   function Classify_Visibility
     (Viewport : Rectangle;
      Bounds   : Rectangle)
      return Visibility
     with
       Global => null,
       Post =>
         (case Classify_Visibility'Result is
            when Fully_Offscreen => not Intersects (Viewport, Bounds),
            when Fully_Visible   => Contains (Viewport, Bounds),
            when Partially_Visible =>
              Intersects (Viewport, Bounds)
              and then not Contains (Viewport, Bounds));

   function Rectangle_Count (Area : Region) return Natural
     with
       Global => null,
       Post => Rectangle_Count'Result <= Area.Capacity;

   function Rectangle_At
     (Area  : Region;
      Index : Positive)
      return Rectangle
     with
       Global => null,
       Post =>
         (if Index > Rectangle_Count (Area) then
            Is_Empty (Rectangle_At'Result));

   procedure Clear (Area : in out Region)
     with
       Global => null,
       Post => Rectangle_Count (Area) = 0;

   procedure Add_Rectangle
     (Area  : in out Region;
      Box   : Rectangle;
     Added : out Boolean)
     with
       Global => null,
       Post =>
         Rectangle_Count (Area) <= Area.Capacity
         and then Added =
           (not Is_Empty (Box)
            and then Rectangle_Count (Area'Old) < Area.Capacity)
         and then
           (if Added then
              Rectangle_Count (Area) = Rectangle_Count (Area'Old) + 1
            else
              Rectangle_Count (Area) = Rectangle_Count (Area'Old));

   function Contains (Area : Region; P : Point) return Boolean
     with Global => null;

   function Intersects (Area : Region; Box : Rectangle) return Boolean
     with
       Global => null,
       Post => (if Intersects'Result then not Is_Empty (Box));

   function Bounds (Area : Region) return Rectangle
     with
       Global => null,
       Post =>
         (if Rectangle_Count (Area) = 0 then Is_Empty (Bounds'Result));

   function Clip
     (Area     : Region;
      Viewport : Rectangle)
      return Region
     with
       Global => null,
       Post =>
         Rectangle_Count (Clip'Result) <= Area.Capacity
         and then
           (if Is_Empty (Viewport) then Rectangle_Count (Clip'Result) = 0);

private

   type Rectangle_Array is array (Positive range <>) of Rectangle;

   type Region (Capacity : Natural) is record
      Count      : Natural := 0;
      Rectangles : Rectangle_Array (1 .. Capacity);
   end record
     with Type_Invariant => Count <= Capacity;

end A11y.Geometry;
