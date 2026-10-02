with Ada.Containers.Vectors;

with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Tables is

   Max_Materialized_Cells : constant Natural := 65_536;

   type Logical_Index is new Natural;

   type Coordinate_Space is
     (Logical_Coordinates,
      Display_Coordinates);

   type Header_Scope is
     (Not_Header,
      Row_Header,
      Column_Header,
      Row_And_Column_Header,
      Corner_Header);

   type Sort_Order is
     (Not_Sorted,
      Ascending,
      Descending,
      Other_Sort_Order);

   type Coordinate_Space_Metadata is record
      Stable_Name         : access constant String;
      Stable_Node_Based   : Boolean := True;
      Presentation_Based  : Boolean := False;
   end record;

   type Header_Scope_Metadata is record
      Stable_Name      : access constant String;
      Applies_To_Rows  : Boolean := False;
      Applies_To_Cols  : Boolean := False;
   end record;

   type Sort_Order_Metadata is record
      Stable_Name : access constant String;
      Is_Sorted   : Boolean := False;
      Directional : Boolean := False;
   end record;

   type Cell_Coordinates is record
      Row    : Logical_Index := 0;
      Column : Logical_Index := 0;
   end record;

   type Logical_Range is record
      First : Logical_Index := 0;
      Count : Logical_Index := 0;
   end record;

   type Cell_Reference is record
      Node   : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Coords : Cell_Coordinates;
      Row_Span    : Positive := 1;
      Column_Span : Positive := 1;
   end record;

   type Sort_State is record
      Order    : Sort_Order := Not_Sorted;
      Key_Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
   end record;

   type Table_Metadata is private;
   type Table_Snapshot is private;

   procedure Configure
     (Self    : in out Table_Snapshot;
      Rows    : Logical_Index;
      Columns : Logical_Index);

   procedure Configure_Displayed
     (Self    : in out Table_Snapshot;
      Rows    : Logical_Index;
      Columns : Logical_Index;
      Result  : out A11y.Results.Result);

   procedure Configure_Visible
     (Self    : in out Table_Snapshot;
      Rows    : Logical_Range;
      Columns : Logical_Range;
      Result  : out A11y.Results.Result);

   function Empty_Metadata return Table_Metadata
   with SPARK_Mode => On;
   function Row_Count (Self : Table_Metadata) return Logical_Index
   with SPARK_Mode => On;
   function Column_Count (Self : Table_Metadata) return Logical_Index
   with SPARK_Mode => On;
   function Displayed_Row_Count (Self : Table_Metadata) return Logical_Index
   with SPARK_Mode => On;
   function Displayed_Column_Count
     (Self : Table_Metadata)
      return Logical_Index
   with SPARK_Mode => On;
   function Visible_Rows (Self : Table_Metadata) return Logical_Range
   with SPARK_Mode => On;
   function Visible_Columns (Self : Table_Metadata) return Logical_Range
   with SPARK_Mode => On;
   function Current_Cell
     (Self : Table_Metadata)
      return A11y.Node_Ids.Node_Id
   with SPARK_Mode => On;
   function Current_Sort (Self : Table_Metadata) return Sort_State
   with SPARK_Mode => On;
   function Materialized_Cell_Count (Self : Table_Metadata) return Natural
   with SPARK_Mode => On;
   function Capacity (Self : Table_Metadata) return Natural
   with SPARK_Mode => On;

   function Metadata_Of (Self : Table_Snapshot) return Table_Metadata;
   function Row_Count (Self : Table_Snapshot) return Logical_Index;
   function Column_Count (Self : Table_Snapshot) return Logical_Index;
   function Displayed_Row_Count (Self : Table_Snapshot) return Logical_Index;
   function Displayed_Column_Count (Self : Table_Snapshot) return Logical_Index;
   function Visible_Rows (Self : Table_Snapshot) return Logical_Range;
   function Visible_Columns (Self : Table_Snapshot) return Logical_Range;
   function Current_Cell (Self : Table_Snapshot) return A11y.Node_Ids.Node_Id;
   function Current_Sort (Self : Table_Snapshot) return Sort_State;
   function Materialized_Cell_Count (Self : Table_Snapshot) return Natural;
   function Capacity (Self : Table_Snapshot) return Natural;
   function Validate (Self : Table_Snapshot) return A11y.Results.Result;

   procedure Set_Capacity
     (Self         : in out Table_Snapshot;
      New_Capacity : Natural;
      Result       : out A11y.Results.Result);

   procedure Configure_Limits
     (Self   : in out Table_Snapshot;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result);

   procedure Add_Cell
     (Self        : in out Table_Snapshot;
      Node        : A11y.Node_Ids.Node_Id;
      Row         : Logical_Index;
      Column      : Logical_Index;
      Row_Span    : Positive := 1;
      Column_Span : Positive := 1;
      Result      : out A11y.Results.Result);

   procedure Set_Current_Cell
     (Self   : in out Table_Snapshot;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result);

   procedure Clear_Current_Cell
     (Self   : in out Table_Snapshot;
      Result : out A11y.Results.Result);

   procedure Set_Sort
     (Self     : in out Table_Snapshot;
      Key_Node : A11y.Node_Ids.Node_Id;
      Order    : Sort_Order;
      Result   : out A11y.Results.Result);

   procedure Clear_Sort
     (Self   : in out Table_Snapshot;
      Result : out A11y.Results.Result);

   function Cell_At
     (Self   : Table_Snapshot;
      Row    : Logical_Index;
      Column : Logical_Index)
      return Cell_Reference;

   function Resolve_Cell
     (Self   : Table_Snapshot;
      Row    : Logical_Index;
      Column : Logical_Index;
      Result : out A11y.Results.Result)
      return Cell_Reference;

   function Coordinates_Of
     (Self : Table_Snapshot;
      Node : A11y.Node_Ids.Node_Id)
      return Cell_Coordinates;

   function Resolve_Coordinates
     (Self   : Table_Snapshot;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
      return Cell_Coordinates;

   function Metadata
     (Space : Coordinate_Space)
      return Coordinate_Space_Metadata;

   function Stable_Name (Space : Coordinate_Space) return String;

   function Metadata
     (Scope : Header_Scope)
      return Header_Scope_Metadata;

   function Stable_Name (Scope : Header_Scope) return String;

   function Metadata
     (Order : Sort_Order)
      return Sort_Order_Metadata;

   function Stable_Name (Order : Sort_Order) return String;

   function Is_Presentation_Space
     (Space : Coordinate_Space)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Is_Presentation_Space'Result =
       (Space = Display_Coordinates);

   function Is_Header
     (Scope : Header_Scope)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Is_Header'Result = (Scope /= Not_Header);

   function Header_Applies_To_Rows
     (Scope : Header_Scope)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Header_Applies_To_Rows'Result =
       (Scope in Row_Header | Row_And_Column_Header | Corner_Header);

   function Header_Applies_To_Columns
     (Scope : Header_Scope)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Header_Applies_To_Columns'Result =
       (Scope in Column_Header | Row_And_Column_Header | Corner_Header);

   function Is_Sorted
     (Order : Sort_Order)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Is_Sorted'Result = (Order /= Not_Sorted);

   function Is_Directional_Sort
     (Order : Sort_Order)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Is_Directional_Sort'Result =
       (Order in Ascending | Descending);

   function Sort_Key_Required
     (Order : Sort_Order)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Sort_Key_Required'Result = Is_Sorted (Order);

   function Range_Fits
     (Visible : Logical_Range;
      Limit   : Logical_Index)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Range_Fits'Result =
       (Visible.First <= Limit
        and then Visible.Count <= Limit - Visible.First);

   function Span_Fits
     (Start : Logical_Index;
      Limit : Logical_Index;
      Span  : Positive)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Span_Fits'Result =
       (Start < Limit
        and then Natural (Span) <= Natural (Limit - Start));

   function Covers
     (Cell        : Cell_Coordinates;
      Row         : Logical_Index;
      Column      : Logical_Index;
      Row_Span    : Positive;
      Column_Span : Positive)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Covers'Result =
       (Row >= Cell.Row
        and then Column >= Cell.Column
        and then Natural (Row - Cell.Row) < Row_Span
        and then Natural (Column - Cell.Column) < Column_Span);

   type Table_Provider is limited interface;

   function Current_Table
     (Self : Table_Provider)
      return Table_Snapshot is abstract;

   function Resolve_Cell
     (Self   : Table_Provider;
      Row    : Logical_Index;
      Column : Logical_Index;
      Result : out A11y.Results.Result)
      return Cell_Reference is abstract;

   function Resolve_Coordinates
     (Self   : Table_Provider;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
      return Cell_Coordinates is abstract;

   function Current_Table_Safely
     (Self   : Table_Provider'Class;
      Result : out A11y.Results.Result)
      return Table_Snapshot;

   function Resolve_Cell_Safely
     (Self   : Table_Provider'Class;
      Row    : Logical_Index;
      Column : Logical_Index;
      Result : out A11y.Results.Result)
      return Cell_Reference;

   function Resolve_Coordinates_Safely
     (Self   : Table_Provider'Class;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
      return Cell_Coordinates;

private
   package Cell_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Cell_Reference);

   type Table_Metadata is record
      Rows  : Logical_Index := 0;
      Cols  : Logical_Index := 0;
      Displayed_Rows : Logical_Index := 0;
      Displayed_Cols : Logical_Index := 0;
      Visible_Row_Range : Logical_Range := (First => 0, Count => 0);
      Visible_Column_Range : Logical_Range := (First => 0, Count => 0);
      Current_Cell_Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Sort : Sort_State;
      Count : Natural := 0;
      Limit : Natural := Max_Materialized_Cells;
   end record;

   type Table_Snapshot is record
      Metadata : Table_Metadata;
      Cells : Cell_Vectors.Vector;
   end record;

end A11y.Tables;
