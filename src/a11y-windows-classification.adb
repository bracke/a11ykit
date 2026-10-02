package body A11y.Windows.Classification is
   pragma SPARK_Mode (On);

   function Is_Top_Level_Kind
     (Kind : Surface_Kind)
      return Standard.Boolean is
     (Kind in Window | Dialog | Modal_Dialog | Palette | Inspector |
              Splash | Notification | Utility_Window);

   function Is_Modal_Kind
     (Kind : Surface_Kind)
      return Standard.Boolean is
     (Kind = Modal_Dialog);

   function Is_Operation_State
     (Flag : Surface_State_Flag)
      return Standard.Boolean is
     (Flag in Closable | Resizable | Movable);

   function Has_State
     (State : Surface_State;
      Flag  : Surface_State_Flag)
      return Standard.Boolean is
     (case Flag is
        when Visible    => State.Visible,
        when Active     => State.Active,
        when Modal      => State.Modal,
        when Minimized  => State.Minimized,
        when Maximized  => State.Maximized,
        when Fullscreen => State.Fullscreen,
        when Closable   => State.Closable,
        when Resizable  => State.Resizable,
        when Movable    => State.Movable);

   function Is_Modal_Surface
     (Item : Surface_Metadata)
      return Standard.Boolean is
     (Is_Modal_Kind (Item.Kind) or else Item.State.Modal);

   function State_Is_Coherent
     (State : Surface_State)
      return Standard.Boolean is
     ((not State.Active or else State.Visible)
      and then (not State.Active or else not State.Minimized)
      and then
        (not State.Minimized
         or else (not State.Maximized and then not State.Fullscreen))
      and then (not State.Maximized or else not State.Fullscreen));

end A11y.Windows.Classification;
