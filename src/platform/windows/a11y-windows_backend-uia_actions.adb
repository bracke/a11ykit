package body A11y.Windows_Backend.UIA_Actions is
   use type A11y.Results.Status_Code;

   function Pattern_Set
     (Actions : A11y.Actions.Action_Set)
      return UIA_Pattern_Set
   is
      Result : UIA_Pattern_Set := Empty_UIA_Pattern_Set;
   begin
      if Actions (A11y.Actions.Activate)
        or else Actions (A11y.Actions.Press)
        or else Actions (A11y.Actions.Open)
      then
         Result (Invoke) := True;
      end if;

      if Actions (A11y.Actions.Toggle) then
         Result (Toggle) := True;
      end if;

      if Actions (A11y.Actions.Expand)
        or else Actions (A11y.Actions.Collapse)
        or else Actions (A11y.Actions.Show_Menu)
        or else Actions (A11y.Actions.Dismiss)
      then
         Result (Expand_Collapse) := True;
      end if;

      if Actions (A11y.Actions.Select_Item)
        or else Actions (A11y.Actions.Deselect)
      then
         Result (Selection_Item) := True;
      end if;

      if Actions (A11y.Actions.Scroll_Into_View) then
         Result (Scroll_Item) := True;
      end if;

      if Actions (A11y.Actions.Close) then
         Result (Window) := True;
      end if;

      return Result;
   end Pattern_Set;

   function Supported
     (Pattern   : UIA_Pattern;
      Operation : UIA_Action)
      return Action_Mapping is
     (Supported => True,
      Pattern   => Pattern,
      Operation => Operation,
      Status    => A11y.Results.Success);

   function Map_Action
     (Actions : A11y.Actions.Action_Set;
      Action  : A11y.Actions.Action_Id)
      return Action_Mapping is
   begin
      if not Actions (Action) then
         return
           (Supported => False,
            Pattern   => Invoke,
            Operation => Invoke_Invoke,
            Status    => A11y.Results.Unsupported_Action);
      end if;

      case Action is
         when A11y.Actions.Activate | A11y.Actions.Press |
              A11y.Actions.Open =>
            return Supported (Invoke, Invoke_Invoke);
         when A11y.Actions.Toggle =>
            return Supported (Toggle, Toggle_Toggle);
         when A11y.Actions.Expand =>
            return Supported
              (Expand_Collapse, Expand_Collapse_Expand);
         when A11y.Actions.Collapse =>
            return Supported
              (Expand_Collapse, Expand_Collapse_Collapse);
         when A11y.Actions.Show_Menu =>
            return Supported
              (Expand_Collapse, Expand_Collapse_Expand);
         when A11y.Actions.Dismiss =>
            return Supported
              (Expand_Collapse, Expand_Collapse_Collapse);
         when A11y.Actions.Select_Item =>
            return Supported
              (Selection_Item, Selection_Item_Select);
         when A11y.Actions.Deselect =>
            return Supported
              (Selection_Item, Selection_Item_Remove_From_Selection);
         when A11y.Actions.Scroll_Into_View =>
            return Supported
              (Scroll_Item, Scroll_Item_Scroll_Into_View);
         when A11y.Actions.Set_Focus =>
            return Supported (Invoke, Fragment_Set_Focus);
         when A11y.Actions.Close =>
            return Supported (Window, Window_Close);
         when others =>
            return
              (Supported => False,
               Pattern   => Invoke,
               Operation => Invoke_Invoke,
               Status    => A11y.Results.Unsupported_Action);
      end case;
   exception
      when others =>
         return
           (Supported => False,
            Pattern   => Invoke,
            Operation => Invoke_Invoke,
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
            Pattern   => Invoke,
            Operation => Invoke_Invoke,
            Status    => Validation.Status);
      end if;

      return Map_Action (Actions, Action);
   exception
      when others =>
         return
           (Supported => False,
            Pattern   => Invoke,
            Operation => Invoke_Invoke,
            Status    => A11y.Results.Internal_Error);
   end Map_Action;

end A11y.Windows_Backend.UIA_Actions;
