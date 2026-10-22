with A11y.Actions;
with A11y.Capabilities;
with A11y.Roles;
with A11y.States;

--  What a screen reader may do to an element, from what the element is:
--  the same on every host, so each native provider offers the same.
package A11y.Element_Actions is

   --  Activate what acts, focus what takes the focus, expand what expands,
   --  toggle check boxes and toggle buttons, select what is selectable,
   --  close windows, and scroll anything into view.
   function For_Element
     (Role         : A11y.Roles.Role;
      States       : A11y.States.State_Set;
      Capabilities : A11y.Capabilities.Capability_Set)
      return A11y.Actions.Action_Set;

end A11y.Element_Actions;
