package body A11y.Selection.Classification is
   pragma SPARK_Mode (On);

   function Allows_Selection
     (Mode : Selection_Mode)
      return Standard.Boolean is
     (Mode /= None);

   function Allows_Multiple
     (Mode : Selection_Mode)
      return Standard.Boolean is
     (Mode in Multiple | Contiguous_Multiple | Extended);

   function Allows_Range
     (Mode : Selection_Mode)
      return Standard.Boolean is
     (Mode in Contiguous_Multiple | Extended);

   function Allows_Required_Selection
     (Mode : Selection_Mode)
      return Standard.Boolean is
     (Allows_Selection (Mode));

   function Count_Allowed
     (Mode  : Selection_Mode;
      Count : Natural)
      return Standard.Boolean is
     ((Mode = None and then Count = 0)
      or else (Mode = Single and then Count <= 1)
      or else (Mode in Multiple | Contiguous_Multiple | Extended));

   function Is_Known_Direction
     (Direction : Selection_Direction)
      return Standard.Boolean is
     (Direction in No_Direction | Forward | Backward);

   function Is_Range_Direction
     (Direction : Selection_Direction)
      return Standard.Boolean is
     (Direction in Forward | Backward);

   function Direction_Allowed
     (Mode      : Selection_Mode;
      Direction : Selection_Direction)
      return Standard.Boolean is
     (if Is_Range_Direction (Direction) then Allows_Range (Mode)
      else Direction /= Unknown);

end A11y.Selection.Classification;
