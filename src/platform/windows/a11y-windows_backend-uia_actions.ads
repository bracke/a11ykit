with A11y.Actions;
with A11y.Results;
with A11y.States;

package A11y.Windows_Backend.UIA_Actions is

   type UIA_Pattern is
     (Invoke,
      Toggle,
      Expand_Collapse,
      Value,
      Range_Value,
      Selection,
      Selection_Item,
      Scroll_Item,
      Window);

   type UIA_Pattern_Set is array (UIA_Pattern) of Boolean;

   Empty_UIA_Pattern_Set : constant UIA_Pattern_Set := [others => False];

   type UIA_Action is
     (Invoke_Invoke,
      Toggle_Toggle,
      Expand_Collapse_Expand,
      Expand_Collapse_Collapse,
      Value_Set_Value,
      Range_Value_Set_Value,
      Selection_Item_Select,
      Selection_Item_Remove_From_Selection,
      Scroll_Item_Scroll_Into_View,
      Fragment_Set_Focus,
      Window_Close);

   type Action_Mapping is record
      Supported : Boolean := False;
      Pattern   : UIA_Pattern := Invoke;
      Operation : UIA_Action := Invoke_Invoke;
      Status    : A11y.Results.Status_Code := A11y.Results.Unsupported_Action;
   end record;

   function Pattern_Set
     (Actions : A11y.Actions.Action_Set)
      return UIA_Pattern_Set;

   function Map_Action
     (Actions : A11y.Actions.Action_Set;
      Action  : A11y.Actions.Action_Id)
      return Action_Mapping;

   function Map_Action
     (Actions : A11y.Actions.Action_Set;
      Action  : A11y.Actions.Action_Id;
      States  : A11y.States.State_Set)
      return Action_Mapping;

end A11y.Windows_Backend.UIA_Actions;
