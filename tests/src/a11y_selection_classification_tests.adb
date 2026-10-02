with A11y.Selection;
with A11y.Selection.Classification;

with A11ykit_Test_Support;

package body A11y_Selection_Classification_Tests is
   procedure Check (Condition : Boolean; Message : String)
      renames A11ykit_Test_Support.Check;

   procedure Run is
   begin
      Check
        (A11y.Selection.Classification.Allows_Selection
           (A11y.Selection.Single)
         and then
           not A11y.Selection.Classification.Allows_Selection
             (A11y.Selection.None),
         "selection classification distinguishes selectable modes");
      Check
        (A11y.Selection.Classification.Allows_Multiple
           (A11y.Selection.Extended)
         and then A11y.Selection.Classification.Allows_Range
           (A11y.Selection.Contiguous_Multiple)
         and then not A11y.Selection.Classification.Count_Allowed
           (A11y.Selection.Single, 2),
         "selection classification preserves multiple and single-count semantics");
      Check
        (A11y.Selection.Classification.Direction_Allowed
           (A11y.Selection.Extended, A11y.Selection.Backward)
         and then not A11y.Selection.Classification.Direction_Allowed
           (A11y.Selection.Single, A11y.Selection.Forward)
         and then not A11y.Selection.Classification.Is_Known_Direction
           (A11y.Selection.Unknown),
         "selection classification validates range direction semantics");
   end Run;
end A11y_Selection_Classification_Tests;
