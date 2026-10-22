package body A11y.Element_Actions is

   function For_Element
     (Role         : A11y.Roles.Role;
      States       : A11y.States.State_Set;
      Capabilities : A11y.Capabilities.Capability_Set)
      return A11y.Actions.Action_Set
   is
      use type A11y.Roles.Role;
      Actions : A11y.Actions.Action_Set := A11y.Actions.Empty_Action_Set;
   begin
      if Capabilities (A11y.Capabilities.Action) then
         Actions (A11y.Actions.Activate) := True;
         Actions (A11y.Actions.Press) := True;
      end if;
      if States (A11y.States.Focusable) then
         Actions (A11y.Actions.Set_Focus) := True;
      end if;
      if States (A11y.States.Expandable) then
         Actions (A11y.Actions.Expand) := True;
         Actions (A11y.Actions.Collapse) := True;
      end if;
      if Role in A11y.Roles.Check_Box | A11y.Roles.Toggle_Button then
         Actions (A11y.Actions.Toggle) := True;
      end if;
      if States (A11y.States.Selectable) then
         Actions (A11y.Actions.Select_Item) := True;
      end if;
      if Role in A11y.Roles.Window | A11y.Roles.Dialog then
         Actions (A11y.Actions.Close) := True;
      end if;
      Actions (A11y.Actions.Scroll_Into_View) := True;
      return Actions;
   end For_Element;

end A11y.Element_Actions;
