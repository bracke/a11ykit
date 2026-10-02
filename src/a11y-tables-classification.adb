package body A11y.Tables.Classification is
   pragma SPARK_Mode (On);

   function Is_Presentation_Space
     (Space : Coordinate_Space)
      return Boolean is
     (Space = Display_Coordinates);

   function Is_Header
     (Scope : Header_Scope)
      return Boolean is
     (Scope /= Not_Header);

   function Header_Applies_To_Rows
     (Scope : Header_Scope)
      return Boolean is
     (Scope in Row_Header | Row_And_Column_Header | Corner_Header);

   function Header_Applies_To_Columns
     (Scope : Header_Scope)
      return Boolean is
     (Scope in Column_Header | Row_And_Column_Header | Corner_Header);

   function Is_Sorted
     (Order : Sort_Order)
      return Boolean is
     (Order /= Not_Sorted);

   function Is_Directional_Sort
     (Order : Sort_Order)
      return Boolean is
     (Order in Ascending | Descending);

   function Sort_Key_Required
     (Order : Sort_Order)
      return Boolean is
     (Is_Sorted (Order));

   function Range_Fits
     (Visible : Logical_Range;
      Limit   : Logical_Index)
      return Boolean is
     (Visible.First <= Limit
      and then Visible.Count <= Limit - Visible.First);

   function Span_Fits
     (Start : Logical_Index;
      Limit : Logical_Index;
      Span  : Positive)
      return Boolean is
     (Start < Limit
      and then Natural (Span) <= Natural (Limit - Start));

   function Covers
     (Cell   : Cell_Coordinates;
      Row    : Logical_Index;
      Column : Logical_Index;
      Row_Span    : Positive;
      Column_Span : Positive)
      return Boolean is
     (Row >= Cell.Row
      and then Column >= Cell.Column
      and then Natural (Row - Cell.Row) < Row_Span
      and then Natural (Column - Cell.Column) < Column_Span);

end A11y.Tables.Classification;
