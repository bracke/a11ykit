with A11y.Results;

package A11y.Text.Classification is
   pragma SPARK_Mode (On);
   use type A11y.Results.Status_Code;

   function Exposes_Text
     (Policy : Protected_Text_Policy)
      return Boolean
   with
      Global => null,
      Post => Exposes_Text'Result = (Policy = Plain_Text);

   function Is_Protected
     (Policy : Protected_Text_Policy)
      return Boolean
   with
      Global => null,
      Post => Is_Protected'Result = (Policy = Protected_Text);

   function Edit_Requires_Range
     (Kind : Text_Edit_Kind)
      return Boolean
   with
      Global => null,
      Post => Edit_Requires_Range'Result = (Kind /= Set_Text);

   function Edit_Requires_Text
     (Kind : Text_Edit_Kind)
      return Boolean
   with
      Global => null,
      Post => Edit_Requires_Text'Result =
        (Kind in Insert_Text | Replace_Text | Set_Text);

   function Edit_Requires_Nonempty_Range
     (Kind : Text_Edit_Kind)
      return Boolean
   with
      Global => null,
      Post => Edit_Requires_Nonempty_Range'Result =
        (Kind in Delete_Text | Replace_Text);

   function Edit_Span_Count_Allowed
     (Kind  : Text_Edit_Kind;
      Count : Natural)
      return Boolean
   with
      Global => null,
      Post => Edit_Span_Count_Allowed'Result =
        ((if Edit_Requires_Nonempty_Range (Kind) then Count > 0 else True)
         and then (if Kind = Set_Text then Count = 0 else True));

   function Edit_Allowed_By_Policy
     (Policy    : Protected_Text_Policy;
      Read_Only : Boolean)
      return Boolean
   with
      Global => null,
      Post => Edit_Allowed_By_Policy'Result =
        (Policy = Plain_Text and then not Read_Only);

   function Edit_Policy_Status
     (Policy    : Protected_Text_Policy;
      Read_Only : Boolean)
      return A11y.Results.Status_Code
   with
      Global => null,
      Post =>
        (if Policy = Protected_Text then
           A11y.Results."="
             (Edit_Policy_Status'Result, A11y.Results.Permission_Denied)
         elsif Read_Only then
           A11y.Results."="
             (Edit_Policy_Status'Result, A11y.Results.Read_Only)
         else
           A11y.Results."="
             (Edit_Policy_Status'Result, A11y.Results.Success));

end A11y.Text.Classification;
