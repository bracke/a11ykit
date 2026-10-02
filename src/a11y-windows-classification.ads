package A11y.Windows.Classification is
   pragma SPARK_Mode (On);

   function Is_Top_Level_Kind
     (Kind : Surface_Kind)
      return Standard.Boolean
   with
     Global => null,
     Post =>
       Is_Top_Level_Kind'Result =
         (Kind in Window | Dialog | Modal_Dialog | Palette | Inspector |
                  Splash | Notification | Utility_Window);

   function Is_Modal_Kind
     (Kind : Surface_Kind)
      return Standard.Boolean
   with
     Global => null,
     Post => Is_Modal_Kind'Result = (Kind = Modal_Dialog);

   function Is_Operation_State
     (Flag : Surface_State_Flag)
      return Standard.Boolean
   with
     Global => null,
     Post =>
       Is_Operation_State'Result =
         (Flag in Closable | Resizable | Movable);

   function Has_State
     (State : Surface_State;
      Flag  : Surface_State_Flag)
      return Standard.Boolean
   with
     Global => null,
     Post =>
       (case Flag is
          when Visible    => Has_State'Result = State.Visible,
          when Active     => Has_State'Result = State.Active,
          when Modal      => Has_State'Result = State.Modal,
          when Minimized  => Has_State'Result = State.Minimized,
          when Maximized  => Has_State'Result = State.Maximized,
          when Fullscreen => Has_State'Result = State.Fullscreen,
          when Closable   => Has_State'Result = State.Closable,
          when Resizable  => Has_State'Result = State.Resizable,
          when Movable    => Has_State'Result = State.Movable);

   function Is_Modal_Surface
     (Item : Surface_Metadata)
      return Standard.Boolean
   with
     Global => null,
     Post =>
       Is_Modal_Surface'Result =
         (Is_Modal_Kind (Item.Kind) or else Item.State.Modal);

   function State_Is_Coherent
     (State : Surface_State)
      return Standard.Boolean
   with
     Global => null,
     Post =>
       State_Is_Coherent'Result =
         ((not State.Active or else State.Visible)
          and then (not State.Active or else not State.Minimized)
          and then
            (not State.Minimized
             or else (not State.Maximized and then not State.Fullscreen))
          and then (not State.Maximized or else not State.Fullscreen));

end A11y.Windows.Classification;
