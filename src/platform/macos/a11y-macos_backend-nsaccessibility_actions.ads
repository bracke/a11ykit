with A11y.Actions;
with A11y.Results;
with A11y.States;

package A11y.MacOS_Backend.NSAccessibility_Actions is

   type NSAX_Action is
     (Press,
      Expand,
      Collapse,
      Show_Menu,
      Confirm,
      Cancel,
      Increment,
      Decrement,
      Pick,
      Raise_Item,
      Scroll_To_Visible);

   type NSAX_Action_Set is array (NSAX_Action) of Boolean;

   Empty_NSAX_Action_Set : constant NSAX_Action_Set := [others => False];

   type Action_Mapping is record
      Supported : Boolean := False;
      Native    : NSAX_Action := Press;
      Status    : A11y.Results.Status_Code := A11y.Results.Unsupported_Action;
   end record;

   function Action_Set
     (Actions : A11y.Actions.Action_Set)
      return NSAX_Action_Set;

   function Map_Action
     (Actions : A11y.Actions.Action_Set;
      Action  : A11y.Actions.Action_Id)
      return Action_Mapping;

   function Map_Action
     (Actions : A11y.Actions.Action_Set;
      Action  : A11y.Actions.Action_Id;
      States  : A11y.States.State_Set)
      return Action_Mapping;

end A11y.MacOS_Backend.NSAccessibility_Actions;
