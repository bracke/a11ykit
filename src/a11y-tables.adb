with A11y.Tables.Classification;

package body A11y.Tables is
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Resource_Limits.Limit_Value;

   Logical_Coordinates_Name : aliased constant String := "logical";
   Display_Coordinates_Name : aliased constant String := "display";

   Not_Header_Name : aliased constant String := "not-header";
   Row_Header_Name : aliased constant String := "row-header";
   Column_Header_Name : aliased constant String := "column-header";
   Row_And_Column_Header_Name : aliased constant String :=
     "row-and-column-header";
   Corner_Header_Name : aliased constant String := "corner-header";

   Not_Sorted_Name : aliased constant String := "not-sorted";
   Ascending_Name : aliased constant String := "ascending";
   Descending_Name : aliased constant String := "descending";
   Other_Sort_Order_Name : aliased constant String := "other";

   function Metadata
     (Space : Coordinate_Space)
      return Coordinate_Space_Metadata is
     (case Space is
        when Logical_Coordinates =>
          (Stable_Name        => Logical_Coordinates_Name'Access,
           Stable_Node_Based  => True,
           Presentation_Based => False),
        when Display_Coordinates =>
          (Stable_Name        => Display_Coordinates_Name'Access,
           Stable_Node_Based  => True,
           Presentation_Based => True));

   function Stable_Name (Space : Coordinate_Space) return String is
     (Metadata (Space).Stable_Name.all);

   function Metadata
     (Scope : Header_Scope)
      return Header_Scope_Metadata is
     (case Scope is
        when Not_Header =>
          (Stable_Name     => Not_Header_Name'Access,
           Applies_To_Rows => False,
           Applies_To_Cols => False),
        when Row_Header =>
          (Stable_Name     => Row_Header_Name'Access,
           Applies_To_Rows => True,
           Applies_To_Cols => False),
        when Column_Header =>
          (Stable_Name     => Column_Header_Name'Access,
           Applies_To_Rows => False,
           Applies_To_Cols => True),
        when Row_And_Column_Header =>
          (Stable_Name     => Row_And_Column_Header_Name'Access,
           Applies_To_Rows => True,
           Applies_To_Cols => True),
        when Corner_Header =>
          (Stable_Name     => Corner_Header_Name'Access,
           Applies_To_Rows => True,
           Applies_To_Cols => True));

   function Stable_Name (Scope : Header_Scope) return String is
     (Metadata (Scope).Stable_Name.all);

   function Metadata
     (Order : Sort_Order)
      return Sort_Order_Metadata is
     (case Order is
        when Not_Sorted =>
          (Stable_Name => Not_Sorted_Name'Access,
           Is_Sorted   => False,
           Directional => False),
        when Ascending =>
          (Stable_Name => Ascending_Name'Access,
           Is_Sorted   => True,
           Directional => True),
        when Descending =>
          (Stable_Name => Descending_Name'Access,
           Is_Sorted   => True,
           Directional => True),
        when Other_Sort_Order =>
          (Stable_Name => Other_Sort_Order_Name'Access,
           Is_Sorted   => True,
           Directional => False));

   function Stable_Name (Order : Sort_Order) return String is
     (Metadata (Order).Stable_Name.all);

   function Is_Presentation_Space
     (Space : Coordinate_Space)
      return Boolean is
     (A11y.Tables.Classification.Is_Presentation_Space (Space))
   with SPARK_Mode => On;

   function Is_Header
     (Scope : Header_Scope)
      return Boolean is
     (A11y.Tables.Classification.Is_Header (Scope))
   with SPARK_Mode => On;

   function Header_Applies_To_Rows
     (Scope : Header_Scope)
      return Boolean is
     (A11y.Tables.Classification.Header_Applies_To_Rows (Scope))
   with SPARK_Mode => On;

   function Header_Applies_To_Columns
     (Scope : Header_Scope)
      return Boolean is
     (A11y.Tables.Classification.Header_Applies_To_Columns (Scope))
   with SPARK_Mode => On;

   function Is_Sorted
     (Order : Sort_Order)
      return Boolean is
     (A11y.Tables.Classification.Is_Sorted (Order))
   with SPARK_Mode => On;

   function Is_Directional_Sort
     (Order : Sort_Order)
      return Boolean is
     (A11y.Tables.Classification.Is_Directional_Sort (Order))
   with SPARK_Mode => On;

   function Sort_Key_Required
     (Order : Sort_Order)
      return Boolean is
     (A11y.Tables.Classification.Sort_Key_Required (Order))
   with SPARK_Mode => On;

   procedure Configure
     (Self    : in out Table_Snapshot;
      Rows    : Logical_Index;
      Columns : Logical_Index)
   is
   begin
      Self.Metadata :=
        (Rows => Rows,
         Cols => Columns,
         Displayed_Rows => Rows,
         Displayed_Cols => Columns,
         Visible_Row_Range => (First => 0, Count => Rows),
         Visible_Column_Range => (First => 0, Count => Columns),
         Current_Cell_Node => A11y.Node_Ids.No_Node,
         Sort => (Order => Not_Sorted,
                  Key_Node => A11y.Node_Ids.No_Node),
         Count => 0,
         Limit => Self.Metadata.Limit);
      Self.Cells.Clear;
   end Configure;

   function Range_Fits
     (Visible : Logical_Range;
      Limit   : Logical_Index)
      return Boolean is
     (A11y.Tables.Classification.Range_Fits (Visible, Limit))
   with SPARK_Mode => On;

   procedure Configure_Displayed
     (Self    : in out Table_Snapshot;
      Rows    : Logical_Index;
      Columns : Logical_Index;
      Result  : out A11y.Results.Result)
   is
   begin
      if Rows > Self.Metadata.Rows or else Columns > Self.Metadata.Cols then
         Result := (Status => A11y.Results.Invalid_Range);
      else
         Self.Metadata.Displayed_Rows := Rows;
         Self.Metadata.Displayed_Cols := Columns;
         Self.Metadata.Visible_Row_Range := (First => 0, Count => Rows);
         Self.Metadata.Visible_Column_Range := (First => 0, Count => Columns);
         Result := A11y.Results.Ok;
      end if;
   end Configure_Displayed;

   procedure Configure_Visible
     (Self    : in out Table_Snapshot;
      Rows    : Logical_Range;
      Columns : Logical_Range;
      Result  : out A11y.Results.Result)
   is
   begin
      if not Range_Fits (Rows, Self.Metadata.Displayed_Rows)
        or else not Range_Fits (Columns, Self.Metadata.Displayed_Cols)
      then
         Result := (Status => A11y.Results.Invalid_Range);
      else
         Self.Metadata.Visible_Row_Range := Rows;
         Self.Metadata.Visible_Column_Range := Columns;
         Result := A11y.Results.Ok;
      end if;
   end Configure_Visible;

   function Empty_Metadata return Table_Metadata is
     (Rows => 0,
      Cols => 0,
      Displayed_Rows => 0,
      Displayed_Cols => 0,
      Visible_Row_Range => (First => 0, Count => 0),
      Visible_Column_Range => (First => 0, Count => 0),
      Current_Cell_Node => A11y.Node_Ids.No_Node,
      Sort => (Order => Not_Sorted,
               Key_Node => A11y.Node_Ids.No_Node),
      Count => 0,
      Limit => Max_Materialized_Cells)
   with SPARK_Mode => On;

   function Row_Count (Self : Table_Metadata) return Logical_Index is
     (Self.Rows);

   function Column_Count (Self : Table_Metadata) return Logical_Index is
     (Self.Cols);

   function Displayed_Row_Count (Self : Table_Metadata) return Logical_Index is
     (Self.Displayed_Rows);

   function Displayed_Column_Count
     (Self : Table_Metadata)
      return Logical_Index is
     (Self.Displayed_Cols);

   function Visible_Rows (Self : Table_Metadata) return Logical_Range is
     (Self.Visible_Row_Range);

   function Visible_Columns (Self : Table_Metadata) return Logical_Range is
     (Self.Visible_Column_Range);

   function Current_Cell
     (Self : Table_Metadata)
      return A11y.Node_Ids.Node_Id is
     (Self.Current_Cell_Node);

   function Current_Sort (Self : Table_Metadata) return Sort_State is
     (Self.Sort);

   function Materialized_Cell_Count (Self : Table_Metadata) return Natural is
     (Self.Count);

   function Capacity (Self : Table_Metadata) return Natural is
     (Self.Limit);

   function Metadata_Of (Self : Table_Snapshot) return Table_Metadata is
     (Self.Metadata);

   function Row_Count (Self : Table_Snapshot) return Logical_Index is
     (Row_Count (Self.Metadata));

   function Column_Count (Self : Table_Snapshot) return Logical_Index is
     (Column_Count (Self.Metadata));

   function Displayed_Row_Count (Self : Table_Snapshot) return Logical_Index is
     (Displayed_Row_Count (Self.Metadata));

   function Displayed_Column_Count (Self : Table_Snapshot) return Logical_Index
   is
     (Displayed_Column_Count (Self.Metadata));

   function Visible_Rows (Self : Table_Snapshot) return Logical_Range is
     (Visible_Rows (Self.Metadata));

   function Visible_Columns (Self : Table_Snapshot) return Logical_Range is
     (Visible_Columns (Self.Metadata));

   function Current_Cell (Self : Table_Snapshot) return A11y.Node_Ids.Node_Id is
     (Current_Cell (Self.Metadata));

   function Current_Sort (Self : Table_Snapshot) return Sort_State is
     (Current_Sort (Self.Metadata));

   function Materialized_Cell_Count (Self : Table_Snapshot) return Natural is
     (Materialized_Cell_Count (Self.Metadata));

   function Capacity (Self : Table_Snapshot) return Natural is
     (Capacity (Self.Metadata));

   procedure Set_Capacity
     (Self         : in out Table_Snapshot;
      New_Capacity : Natural;
      Result       : out A11y.Results.Result)
   is
   begin
      if New_Capacity = 0 or else New_Capacity > Max_Materialized_Cells then
         Result := (Status => A11y.Results.Invalid_Argument);
      elsif New_Capacity < Self.Metadata.Count then
         Result := (Status => A11y.Results.Invalid_State);
      else
         Self.Metadata.Limit := New_Capacity;
         Result := A11y.Results.Ok;
      end if;
   end Set_Capacity;

   procedure Configure_Limits
     (Self   : in out Table_Snapshot;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
   is
      Capacity_Value : constant A11y.Resource_Limits.Limit_Value :=
        A11y.Resource_Limits.Value
          (Limits, A11y.Resource_Limits.Virtual_Node_Realization);
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if not A11y.Results.Succeeded (Result) then
         return;
      end if;

      if Capacity_Value
        > A11y.Resource_Limits.Limit_Value (Max_Materialized_Cells)
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      end if;

      Set_Capacity (Self, Natural (Capacity_Value), Result);
   end Configure_Limits;

   function Covers
     (Cell        : Cell_Coordinates;
      Row         : Logical_Index;
      Column      : Logical_Index;
      Row_Span    : Positive;
      Column_Span : Positive)
      return Boolean is
     (A11y.Tables.Classification.Covers
        (Cell, Row, Column, Row_Span, Column_Span))
   with SPARK_Mode => On;

   function Covers
     (Cell   : Cell_Reference;
      Row    : Logical_Index;
      Column : Logical_Index)
      return Boolean is
     (Row >= Cell.Coords.Row
      and then Column >= Cell.Coords.Column
      and then Natural (Row - Cell.Coords.Row) < Cell.Row_Span
      and then Natural (Column - Cell.Coords.Column) < Cell.Column_Span)
   with SPARK_Mode => On;

   function Last_Row (Cell : Cell_Reference) return Logical_Index is
     (Cell.Coords.Row + Logical_Index (Cell.Row_Span - 1));

   function Last_Column (Cell : Cell_Reference) return Logical_Index is
     (Cell.Coords.Column + Logical_Index (Cell.Column_Span - 1));

   function Overlaps (Left, Right : Cell_Reference) return Boolean is
     (Left.Coords.Row <= Last_Row (Right)
      and then Right.Coords.Row <= Last_Row (Left)
      and then Left.Coords.Column <= Last_Column (Right)
      and then Right.Coords.Column <= Last_Column (Left));

   function Span_Fits
     (Start : Logical_Index;
      Limit : Logical_Index;
      Span  : Positive)
      return Boolean is
     (A11y.Tables.Classification.Span_Fits (Start, Limit, Span))
   with SPARK_Mode => On;

   function Validate (Self : Table_Snapshot) return A11y.Results.Result is
   begin
      if Self.Metadata.Limit = 0
        or else Self.Metadata.Limit > Max_Materialized_Cells
      then
         return (Status => A11y.Results.Invalid_State);
      elsif Self.Metadata.Count /= Natural (Self.Cells.Length) then
         return (Status => A11y.Results.Invalid_State);
      elsif Self.Metadata.Count > Self.Metadata.Limit
        or else Self.Metadata.Count > Max_Materialized_Cells
      then
         return (Status => A11y.Results.Resource_Limit);
      elsif Self.Metadata.Displayed_Rows > Self.Metadata.Rows
        or else Self.Metadata.Displayed_Cols > Self.Metadata.Cols
      then
         return (Status => A11y.Results.Invalid_Range);
      elsif not Range_Fits
        (Self.Metadata.Visible_Row_Range, Self.Metadata.Displayed_Rows)
        or else not Range_Fits
          (Self.Metadata.Visible_Column_Range, Self.Metadata.Displayed_Cols)
      then
         return (Status => A11y.Results.Invalid_Range);
      elsif Self.Metadata.Sort.Order = Not_Sorted
        and then A11y.Node_Ids.Is_Valid (Self.Metadata.Sort.Key_Node)
      then
         return (Status => A11y.Results.Invalid_State);
      elsif Self.Metadata.Sort.Order /= Not_Sorted
        and then not A11y.Node_Ids.Is_Valid (Self.Metadata.Sort.Key_Node)
      then
         return (Status => A11y.Results.Node_Unavailable);
      end if;

      if A11y.Node_Ids.Is_Valid (Self.Metadata.Current_Cell_Node) then
         declare
            Result : A11y.Results.Result;
            Ignored : constant Cell_Coordinates :=
              Resolve_Coordinates
                (Self, Self.Metadata.Current_Cell_Node, Result);
         begin
            if A11y.Results.Failed (Result) then
               return Result;
            end if;
         end;
      end if;

      for Index in 1 .. Self.Metadata.Count loop
         if not A11y.Node_Ids.Is_Valid (Self.Cells (Index).Node) then
            return (Status => A11y.Results.Node_Unavailable);
         elsif not Span_Fits
           (Self.Cells (Index).Coords.Row,
            Self.Metadata.Rows,
            Self.Cells (Index).Row_Span)
           or else not Span_Fits
             (Self.Cells (Index).Coords.Column,
              Self.Metadata.Cols,
              Self.Cells (Index).Column_Span)
         then
            return (Status => A11y.Results.Invalid_Range);
         end if;

         for Other in Index + 1 .. Self.Metadata.Count loop
            if Self.Cells (Index).Node = Self.Cells (Other).Node
              or else Overlaps (Self.Cells (Index), Self.Cells (Other))
            then
               return (Status => A11y.Results.Invalid_State);
            end if;
         end loop;
      end loop;

      return A11y.Results.Ok;
   end Validate;

   procedure Add_Cell
     (Self        : in out Table_Snapshot;
      Node        : A11y.Node_Ids.Node_Id;
      Row         : Logical_Index;
      Column      : Logical_Index;
      Row_Span    : Positive := 1;
      Column_Span : Positive := 1;
      Result      : out A11y.Results.Result)
   is
   begin
      declare
         New_Cell : constant Cell_Reference :=
           (Node        => Node,
            Coords      => (Row => Row, Column => Column),
            Row_Span    => Row_Span,
            Column_Span => Column_Span);
      begin
         if not A11y.Node_Ids.Is_Valid (Node) then
            Result := (Status => A11y.Results.Node_Unavailable);
         elsif not Span_Fits (Row, Self.Metadata.Rows, Row_Span)
           or else not Span_Fits
             (Column, Self.Metadata.Cols, Column_Span)
         then
            Result := (Status => A11y.Results.Invalid_Range);
         elsif Self.Metadata.Count >= Self.Metadata.Limit then
            Result := (Status => A11y.Results.Resource_Limit);
         else
            for Index in 1 .. Self.Metadata.Count loop
               if Overlaps (Self.Cells (Index), New_Cell)
                 or else Self.Cells (Index).Node = Node
               then
                  Result := (Status => A11y.Results.Invalid_State);
                  return;
               end if;
            end loop;

            Self.Cells.Append
              (New_Item =>
                 Cell_Reference'
                   (Node        => Node,
                    Coords      => (Row => Row, Column => Column),
                    Row_Span    => Row_Span,
                    Column_Span => Column_Span));
            Self.Metadata.Count := Natural (Self.Cells.Length);
            Result := A11y.Results.Ok;
         end if;
      end;
   end Add_Cell;

   procedure Set_Current_Cell
     (Self   : in out Table_Snapshot;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
   is
      Ignored : Cell_Coordinates;
   begin
      Ignored := Resolve_Coordinates (Self, Node, Result);
      if A11y.Results.Succeeded (Result) then
         Self.Metadata.Current_Cell_Node := Node;
      end if;
   end Set_Current_Cell;

   procedure Clear_Current_Cell
     (Self   : in out Table_Snapshot;
      Result : out A11y.Results.Result)
   is
   begin
      Self.Metadata.Current_Cell_Node := A11y.Node_Ids.No_Node;
      Result := A11y.Results.Ok;
   end Clear_Current_Cell;

   procedure Set_Sort
     (Self     : in out Table_Snapshot;
      Key_Node : A11y.Node_Ids.Node_Id;
      Order    : Sort_Order;
      Result   : out A11y.Results.Result)
   is
   begin
      if Order = Not_Sorted then
         if A11y.Node_Ids.Is_Valid (Key_Node) then
            Result := (Status => A11y.Results.Invalid_Argument);
         else
            Self.Metadata.Sort := (Order => Not_Sorted,
                                   Key_Node => A11y.Node_Ids.No_Node);
            Result := A11y.Results.Ok;
         end if;
      elsif not A11y.Node_Ids.Is_Valid (Key_Node) then
         Result := (Status => A11y.Results.Node_Unavailable);
      else
         Self.Metadata.Sort := (Order => Order,
                                Key_Node => Key_Node);
         Result := A11y.Results.Ok;
      end if;
   end Set_Sort;

   procedure Clear_Sort
     (Self   : in out Table_Snapshot;
      Result : out A11y.Results.Result)
   is
   begin
      Self.Metadata.Sort := (Order => Not_Sorted,
                             Key_Node => A11y.Node_Ids.No_Node);
      Result := A11y.Results.Ok;
   end Clear_Sort;

   function Cell_At
     (Self   : Table_Snapshot;
      Row    : Logical_Index;
      Column : Logical_Index)
      return Cell_Reference
   is
   begin
      for Index in 1 .. Self.Metadata.Count loop
         if Covers (Self.Cells (Index), Row, Column) then
            return Self.Cells (Index);
         end if;
      end loop;

      return (Node => A11y.Node_Ids.No_Node,
              Coords => (Row => Row, Column => Column),
              Row_Span => 1,
              Column_Span => 1);
   end Cell_At;

   function Resolve_Cell
     (Self   : Table_Snapshot;
      Row    : Logical_Index;
      Column : Logical_Index;
      Result : out A11y.Results.Result)
      return Cell_Reference
   is
      Cell : Cell_Reference;
   begin
      if Row >= Self.Metadata.Rows or else Column >= Self.Metadata.Cols then
         Result := (Status => A11y.Results.Invalid_Range);
         return
           (Node => A11y.Node_Ids.No_Node,
            Coords => (Row => Row, Column => Column),
            Row_Span => 1,
            Column_Span => 1);
      end if;

      Cell := Cell_At (Self, Row, Column);
      if not A11y.Node_Ids.Is_Valid (Cell.Node) then
         Result := (Status => A11y.Results.Node_Unavailable);
      else
         Result := A11y.Results.Ok;
      end if;

      return Cell;
   end Resolve_Cell;

   function Coordinates_Of
     (Self : Table_Snapshot;
      Node : A11y.Node_Ids.Node_Id)
      return Cell_Coordinates
   is
   begin
      for Index in 1 .. Self.Metadata.Count loop
         if Self.Cells (Index).Node = Node then
            return Self.Cells (Index).Coords;
         end if;
      end loop;

      return (Row => 0, Column => 0);
   end Coordinates_Of;

   function Resolve_Coordinates
     (Self   : Table_Snapshot;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
      return Cell_Coordinates
   is
   begin
      if not A11y.Node_Ids.Is_Valid (Node) then
         Result := (Status => A11y.Results.Node_Unavailable);
         return (Row => 0, Column => 0);
      end if;

      for Index in 1 .. Self.Metadata.Count loop
         if Self.Cells (Index).Node = Node then
            Result := A11y.Results.Ok;
            return Self.Cells (Index).Coords;
         end if;
      end loop;

      Result := (Status => A11y.Results.Node_Unavailable);
      return (Row => 0, Column => 0);
   end Resolve_Coordinates;

   function Current_Table_Safely
     (Self   : Table_Provider'Class;
      Result : out A11y.Results.Result)
      return Table_Snapshot
   is
      Snapshot : Table_Snapshot;
   begin
      Snapshot := Self.Current_Table;
      Result := Validate (Snapshot);
      if A11y.Results.Failed (Result) then
         return (Metadata => Empty_Metadata,
                 Cells => <>);
      end if;

      return Snapshot;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return (Metadata => Empty_Metadata,
                 Cells => <>);
   end Current_Table_Safely;

   function Resolve_Cell_Safely
     (Self   : Table_Provider'Class;
      Row    : Logical_Index;
      Column : Logical_Index;
      Result : out A11y.Results.Result)
      return Cell_Reference
   is
      Cell : Cell_Reference;
   begin
      Cell := Self.Resolve_Cell (Row, Column, Result);
      if A11y.Results.Succeeded (Result) then
         if not A11y.Node_Ids.Is_Valid (Cell.Node) then
            Result := (Status => A11y.Results.Node_Unavailable);
            return (Node => A11y.Node_Ids.No_Node,
                    Coords => (Row => Row, Column => Column),
                    Row_Span => 1,
                    Column_Span => 1);
         elsif not Covers (Cell, Row, Column) then
            Result := (Status => A11y.Results.Invalid_State);
            return (Node => A11y.Node_Ids.No_Node,
                    Coords => (Row => Row, Column => Column),
                    Row_Span => 1,
                    Column_Span => 1);
         end if;
      end if;

      return Cell;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return (Node => A11y.Node_Ids.No_Node,
                 Coords => (Row => Row, Column => Column),
                 Row_Span => 1,
                 Column_Span => 1);
   end Resolve_Cell_Safely;

   function Resolve_Coordinates_Safely
     (Self   : Table_Provider'Class;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
      return Cell_Coordinates
   is
   begin
      if not A11y.Node_Ids.Is_Valid (Node) then
         Result := (Status => A11y.Results.Node_Unavailable);
         return (Row => 0, Column => 0);
      end if;

      return Self.Resolve_Coordinates (Node, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return (Row => 0, Column => 0);
   end Resolve_Coordinates_Safely;

end A11y.Tables;
