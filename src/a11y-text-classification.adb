package body A11y.Text.Classification is
   pragma SPARK_Mode (On);

   function Exposes_Text
     (Policy : Protected_Text_Policy)
      return Boolean is
     (Policy = Plain_Text);

   function Is_Protected
     (Policy : Protected_Text_Policy)
      return Boolean is
     (Policy = Protected_Text);

   function Edit_Requires_Range
     (Kind : Text_Edit_Kind)
      return Boolean is
     (Kind /= Set_Text);

   function Edit_Requires_Text
     (Kind : Text_Edit_Kind)
      return Boolean is
     (Kind in Insert_Text | Replace_Text | Set_Text);

   function Edit_Requires_Nonempty_Range
     (Kind : Text_Edit_Kind)
      return Boolean is
     (Kind in Delete_Text | Replace_Text);

   function Edit_Span_Count_Allowed
     (Kind  : Text_Edit_Kind;
      Count : Natural)
      return Boolean is
     ((if Edit_Requires_Nonempty_Range (Kind) then Count > 0 else True)
      and then (if Kind = Set_Text then Count = 0 else True));

   function Edit_Allowed_By_Policy
     (Policy    : Protected_Text_Policy;
      Read_Only : Boolean)
      return Boolean is
     (Policy = Plain_Text and then not Read_Only);

   function Edit_Policy_Status
     (Policy    : Protected_Text_Policy;
      Read_Only : Boolean)
      return A11y.Results.Status_Code is
     (if Policy = Protected_Text then A11y.Results.Permission_Denied
      elsif Read_Only then A11y.Results.Read_Only
      else A11y.Results.Success);

end A11y.Text.Classification;
