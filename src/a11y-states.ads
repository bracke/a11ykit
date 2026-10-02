with A11y.Capabilities;
with A11y.Results;
with A11y.Roles;

package A11y.States is
   pragma SPARK_Mode (On);

   type State_Flag is
     (Enabled,
      Sensitive,
      Visible,
      Showing,
      Focused,
      Focusable,
      Selected,
      Selectable,
      Checked,
      Indeterminate,
      Expanded,
      Expandable,
      Pressed,
      Read_Only,
      Editable,
      Required,
      Invalid,
      Busy,
      Modal,
      Multi_Line,
      Multi_Selectable,
      Visited,
      Offscreen,
      Defunct,
      Active);

   type State_Set is array (State_Flag) of Boolean;

   Empty_State_Set : constant State_Set := [others => False];

   type State_Source is
     (Application_Provided,
      Centrally_Derived);

   type Stable_Name_Access is access constant String;

   type State_Metadata is record
      Stable_Name : Stable_Name_Access;
      Source      : State_Source := Application_Provided;
   end record;

   function Metadata (Flag : State_Flag) return State_Metadata
   with
      Global => null,
      Post =>
        Metadata'Result.Source =
          (case Flag is
             when Showing
                | Focusable
                | Read_Only
                | Editable
                | Offscreen
                | Defunct
                | Active =>
               Centrally_Derived,
             when Enabled
                | Sensitive
                | Visible
                | Focused
                | Selected
                | Selectable
                | Checked
                | Indeterminate
                | Expanded
                | Expandable
                | Pressed
                | Required
                | Invalid
                | Busy
                | Modal
                | Multi_Line
                | Multi_Selectable
                | Visited =>
               Application_Provided);

   function Stable_Name (Flag : State_Flag) return String;

   function Source (Flag : State_Flag) return State_Source
   with
      Global => null,
      Post => Source'Result = Metadata (Flag).Source;

   function Validate (Set : State_Set) return A11y.Results.Result
     with
       Global => null,
       Post =>
         A11y.Results.Succeeded (Validate'Result) =
           (not (Set (Focused) and then not Set (Focusable))
            and then not (Set (Selected) and then not Set (Selectable))
            and then not (Set (Multi_Selectable) and then not Set (Selectable))
            and then not (Set (Expanded) and then not Set (Expandable))
            and then not (Set (Checked) and then Set (Indeterminate))
            and then not (Set (Read_Only) and then Set (Editable))
            and then not (Set (Showing) and then not Set (Visible))
            and then not
              (Set (Defunct)
               and then (Set (Active) or else Set (Focused) or else Set (Showing))));

   function With_State (Base : State_Set; Flag : State_Flag) return State_Set
     with
       Global => null,
       Post =>
         With_State'Result (Flag)
         and then
           (for all Other in State_Flag =>
              (if Other /= Flag then With_State'Result (Other) = Base (Other)));

   function Derive
     (Base         : State_Set;
      Role         : A11y.Roles.Role;
      Capabilities : A11y.Capabilities.Capability_Set)
      return State_Set
      with
        Global => null,
        Post =>
          Derive'Result (Focusable) =
            (Base (Focusable)
             or else
               A11y.Roles."/="
                 (A11y.Roles.Focus_Behavior (Role),
                  A11y.Roles.Never_Focusable))
          and then
            Derive'Result (Editable) =
              (Base (Editable)
               or else Capabilities (A11y.Capabilities.Editable_Text))
          and then
            Derive'Result (Read_Only) =
              (if Capabilities (A11y.Capabilities.Editable_Text) then
                 Base (Read_Only)
               elsif
                 Capabilities (A11y.Capabilities.Text)
                 or else Capabilities (A11y.Capabilities.Value)
               then
                 True
               else
                 Base (Read_Only))
          and then
            (for all Flag in State_Flag =>
               (if Flag not in Focusable | Editable | Read_Only then
                  Derive'Result (Flag) = Base (Flag)));

end A11y.States;
