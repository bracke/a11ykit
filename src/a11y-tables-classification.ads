package A11y.Tables.Classification is
   pragma SPARK_Mode (On);

   function Is_Presentation_Space
     (Space : Coordinate_Space)
      return Boolean
   with
      Global => null,
      Post => Is_Presentation_Space'Result =
        (Space = Display_Coordinates);

   function Is_Header
     (Scope : Header_Scope)
      return Boolean
   with
      Global => null,
      Post => Is_Header'Result = (Scope /= Not_Header);

   function Header_Applies_To_Rows
     (Scope : Header_Scope)
      return Boolean
   with
      Global => null,
      Post => Header_Applies_To_Rows'Result =
        (Scope in Row_Header | Row_And_Column_Header | Corner_Header);

   function Header_Applies_To_Columns
     (Scope : Header_Scope)
      return Boolean
   with
      Global => null,
      Post => Header_Applies_To_Columns'Result =
        (Scope in Column_Header | Row_And_Column_Header | Corner_Header);

   function Is_Sorted
     (Order : Sort_Order)
      return Boolean
   with
      Global => null,
      Post => Is_Sorted'Result = (Order /= Not_Sorted);

   function Is_Directional_Sort
     (Order : Sort_Order)
      return Boolean
   with
      Global => null,
      Post => Is_Directional_Sort'Result =
        (Order in Ascending | Descending);

   function Sort_Key_Required
     (Order : Sort_Order)
      return Boolean
   with
      Global => null,
      Post => Sort_Key_Required'Result = Is_Sorted (Order);

   function Range_Fits
     (Visible : Logical_Range;
      Limit   : Logical_Index)
      return Boolean
   with
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
      Global => null,
      Post => Span_Fits'Result =
        (Start < Limit
         and then Natural (Span) <= Natural (Limit - Start));

   function Covers
     (Cell   : Cell_Coordinates;
      Row    : Logical_Index;
      Column : Logical_Index;
      Row_Span    : Positive;
      Column_Span : Positive)
      return Boolean
   with
      Global => null,
      Post => Covers'Result =
        (Row >= Cell.Row
         and then Column >= Cell.Column
         and then Natural (Row - Cell.Row) < Row_Span
         and then Natural (Column - Cell.Column) < Column_Span);

end A11y.Tables.Classification;
