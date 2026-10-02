package body A11y.States is
   pragma SPARK_Mode (On);
   use type A11y.Roles.Role_Focus_Behavior;

   Enabled_Name : aliased constant String := "enabled";
   Sensitive_Name : aliased constant String := "sensitive";
   Visible_Name : aliased constant String := "visible";
   Showing_Name : aliased constant String := "showing";
   Focused_Name : aliased constant String := "focused";
   Focusable_Name : aliased constant String := "focusable";
   Selected_Name : aliased constant String := "selected";
   Selectable_Name : aliased constant String := "selectable";
   Checked_Name : aliased constant String := "checked";
   Indeterminate_Name : aliased constant String := "indeterminate";
   Expanded_Name : aliased constant String := "expanded";
   Expandable_Name : aliased constant String := "expandable";
   Pressed_Name : aliased constant String := "pressed";
   Read_Only_Name : aliased constant String := "read-only";
   Editable_Name : aliased constant String := "editable";
   Required_Name : aliased constant String := "required";
   Invalid_Name : aliased constant String := "invalid";
   Busy_Name : aliased constant String := "busy";
   Modal_Name : aliased constant String := "modal";
   Multi_Line_Name : aliased constant String := "multi-line";
   Multi_Selectable_Name : aliased constant String := "multi-selectable";
   Visited_Name : aliased constant String := "visited";
   Offscreen_Name : aliased constant String := "offscreen";
   Defunct_Name : aliased constant String := "defunct";
   Active_Name : aliased constant String := "active";

   function Metadata (Flag : State_Flag) return State_Metadata is
     (case Flag is
        when Enabled =>
          (Stable_Name => Enabled_Name'Access,
           Source => Application_Provided),
        when Sensitive =>
          (Stable_Name => Sensitive_Name'Access,
           Source => Application_Provided),
        when Visible =>
          (Stable_Name => Visible_Name'Access,
           Source => Application_Provided),
        when Showing =>
          (Stable_Name => Showing_Name'Access,
           Source => Centrally_Derived),
        when Focused =>
          (Stable_Name => Focused_Name'Access,
           Source => Application_Provided),
        when Focusable =>
          (Stable_Name => Focusable_Name'Access,
           Source => Centrally_Derived),
        when Selected =>
          (Stable_Name => Selected_Name'Access,
           Source => Application_Provided),
        when Selectable =>
          (Stable_Name => Selectable_Name'Access,
           Source => Application_Provided),
        when Checked =>
          (Stable_Name => Checked_Name'Access,
           Source => Application_Provided),
        when Indeterminate =>
          (Stable_Name => Indeterminate_Name'Access,
           Source => Application_Provided),
        when Expanded =>
          (Stable_Name => Expanded_Name'Access,
           Source => Application_Provided),
        when Expandable =>
          (Stable_Name => Expandable_Name'Access,
           Source => Application_Provided),
        when Pressed =>
          (Stable_Name => Pressed_Name'Access,
           Source => Application_Provided),
        when Read_Only =>
          (Stable_Name => Read_Only_Name'Access,
           Source => Centrally_Derived),
        when Editable =>
          (Stable_Name => Editable_Name'Access,
           Source => Centrally_Derived),
        when Required =>
          (Stable_Name => Required_Name'Access,
           Source => Application_Provided),
        when Invalid =>
          (Stable_Name => Invalid_Name'Access,
           Source => Application_Provided),
        when Busy =>
          (Stable_Name => Busy_Name'Access,
           Source => Application_Provided),
        when Modal =>
          (Stable_Name => Modal_Name'Access,
           Source => Application_Provided),
        when Multi_Line =>
          (Stable_Name => Multi_Line_Name'Access,
           Source => Application_Provided),
        when Multi_Selectable =>
          (Stable_Name => Multi_Selectable_Name'Access,
           Source => Application_Provided),
        when Visited =>
          (Stable_Name => Visited_Name'Access,
           Source => Application_Provided),
        when Offscreen =>
          (Stable_Name => Offscreen_Name'Access,
           Source => Centrally_Derived),
        when Defunct =>
          (Stable_Name => Defunct_Name'Access,
           Source => Centrally_Derived),
        when Active =>
          (Stable_Name => Active_Name'Access,
           Source => Centrally_Derived));

   function Stable_Name (Flag : State_Flag) return String is
     (Metadata (Flag).Stable_Name.all);

   function Source (Flag : State_Flag) return State_Source is
     (Metadata (Flag).Source);

   function Validate (Set : State_Set) return A11y.Results.Result is
   begin
      if Set (Focused) and then not Set (Focusable) then
         return (Status => A11y.Results.Invalid_State);
      elsif Set (Selected) and then not Set (Selectable) then
         return (Status => A11y.Results.Invalid_State);
      elsif Set (Multi_Selectable) and then not Set (Selectable) then
         return (Status => A11y.Results.Invalid_State);
      elsif Set (Expanded) and then not Set (Expandable) then
         return (Status => A11y.Results.Invalid_State);
      elsif Set (Checked) and then Set (Indeterminate) then
         return (Status => A11y.Results.Invalid_State);
      elsif Set (Read_Only) and then Set (Editable) then
         return (Status => A11y.Results.Invalid_State);
      elsif Set (Showing) and then not Set (Visible) then
         return (Status => A11y.Results.Invalid_State);
      elsif Set (Defunct)
        and then (Set (Active) or else Set (Focused) or else Set (Showing))
      then
         return (Status => A11y.Results.Invalid_State);
      end if;

      return A11y.Results.Ok;
   end Validate;

   function With_State (Base : State_Set; Flag : State_Flag) return State_Set is
      Result : State_Set := Base;
   begin
      Result (Flag) := True;
      return Result;
   end With_State;

   function Derive
     (Base         : State_Set;
      Role         : A11y.Roles.Role;
      Capabilities : A11y.Capabilities.Capability_Set)
      return State_Set
   is
      Result : State_Set := Base;
      Focus : constant A11y.Roles.Role_Focus_Behavior :=
        A11y.Roles.Focus_Behavior (Role);
   begin
      if Focus /= A11y.Roles.Never_Focusable then
         Result (Focusable) := True;
      end if;

      if Capabilities (A11y.Capabilities.Editable_Text) then
         Result (Editable) := True;
      elsif Capabilities (A11y.Capabilities.Text)
        or else Capabilities (A11y.Capabilities.Value)
      then
         Result (Read_Only) := True;
      end if;

      return Result;
   end Derive;

end A11y.States;
