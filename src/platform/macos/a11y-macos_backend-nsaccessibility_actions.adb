package body A11y.MacOS_Backend.NSAccessibility_Actions is
   use type A11y.Results.Status_Code;

   function Action_Set
     (Actions : A11y.Actions.Action_Set)
      return NSAX_Action_Set
   is
      Result : NSAX_Action_Set := Empty_NSAX_Action_Set;
   begin
      if Actions (A11y.Actions.Activate)
        or else Actions (A11y.Actions.Press)
        or else Actions (A11y.Actions.Toggle)
      then
         Result (Press) := True;
      end if;

      if Actions (A11y.Actions.Expand) then
         Result (Expand) := True;
      end if;

      if Actions (A11y.Actions.Collapse) then
         Result (Collapse) := True;
      end if;

      if Actions (A11y.Actions.Show_Menu) then
         Result (Show_Menu) := True;
      end if;

      if Actions (A11y.Actions.Open) then
         Result (Confirm) := True;
      end if;

      if Actions (A11y.Actions.Dismiss) or else Actions (A11y.Actions.Close)
      then
         Result (Cancel) := True;
      end if;

      if Actions (A11y.Actions.Increment) then
         Result (Increment) := True;
      end if;

      if Actions (A11y.Actions.Decrement) then
         Result (Decrement) := True;
      end if;

      if Actions (A11y.Actions.Select_Item) then
         Result (Pick) := True;
      end if;

      if Actions (A11y.Actions.Set_Focus) then
         Result (Raise_Item) := True;
      end if;

      if Actions (A11y.Actions.Scroll_Into_View) then
         Result (Scroll_To_Visible) := True;
      end if;

      return Result;
   end Action_Set;

   function Supported (Native : NSAX_Action) return Action_Mapping is
     (Supported => True,
      Native    => Native,
      Status    => A11y.Results.Success);

   function Map_Action
     (Actions : A11y.Actions.Action_Set;
      Action  : A11y.Actions.Action_Id)
      return Action_Mapping is
   begin
      if not Actions (Action) then
         return
           (Supported => False,
            Native    => Press,
            Status    => A11y.Results.Unsupported_Action);
      end if;

      case Action is
         when A11y.Actions.Activate |
              A11y.Actions.Press |
              A11y.Actions.Toggle =>
            return Supported (Press);
         when A11y.Actions.Expand =>
            return Supported (Expand);
         when A11y.Actions.Collapse =>
            return Supported (Collapse);
         when A11y.Actions.Show_Menu =>
            return Supported (Show_Menu);
         when A11y.Actions.Open =>
            return Supported (Confirm);
         when A11y.Actions.Dismiss | A11y.Actions.Close =>
            return Supported (Cancel);
         when A11y.Actions.Increment =>
            return Supported (Increment);
         when A11y.Actions.Decrement =>
            return Supported (Decrement);
         when A11y.Actions.Select_Item =>
            return Supported (Pick);
         when A11y.Actions.Set_Focus =>
            return Supported (Raise_Item);
         when A11y.Actions.Scroll_Into_View =>
            return Supported (Scroll_To_Visible);
         when others =>
            return
              (Supported => False,
               Native    => Press,
               Status    => A11y.Results.Unsupported_Action);
      end case;
   exception
      when others =>
         return
           (Supported => False,
            Native    => Press,
            Status    => A11y.Results.Internal_Error);
   end Map_Action;

   function Map_Action
     (Actions : A11y.Actions.Action_Set;
      Action  : A11y.Actions.Action_Id;
      States  : A11y.States.State_Set)
      return Action_Mapping
   is
      Validation : constant A11y.Actions.Action_Result :=
        A11y.Actions.Validate_Request (Actions, Action, States);
   begin
      if Validation.Status /= A11y.Results.Success then
         return
           (Supported => False,
            Native    => Press,
            Status    => Validation.Status);
      end if;

      return Map_Action (Actions, Action);
   exception
      when others =>
         return
           (Supported => False,
            Native    => Press,
            Status    => A11y.Results.Internal_Error);
   end Map_Action;

end A11y.MacOS_Backend.NSAccessibility_Actions;
