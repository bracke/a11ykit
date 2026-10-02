with A11y.Windows.Classification;

package body A11y.Windows is

   Window_Name           : aliased constant String := "window";
   Dialog_Name           : aliased constant String := "dialog";
   Modal_Dialog_Name     : aliased constant String := "modal-dialog";
   Sheet_Name            : aliased constant String := "sheet";
   Popup_Name            : aliased constant String := "popup";
   Popover_Name          : aliased constant String := "popover";
   Menu_Name             : aliased constant String := "menu";
   Context_Menu_Name     : aliased constant String := "context-menu";
   Tooltip_Name          : aliased constant String := "tooltip";
   Palette_Name          : aliased constant String := "palette";
   Inspector_Name        : aliased constant String := "inspector";
   Splash_Name           : aliased constant String := "splash";
   Notification_Name     : aliased constant String := "notification";
   Utility_Window_Name   : aliased constant String := "utility-window";
   Embedded_Surface_Name : aliased constant String := "embedded-surface";

   Visible_Name    : aliased constant String := "visible";
   Active_Name     : aliased constant String := "active";
   Modal_Name      : aliased constant String := "modal";
   Minimized_Name  : aliased constant String := "minimized";
   Maximized_Name  : aliased constant String := "maximized";
   Fullscreen_Name : aliased constant String := "fullscreen";
   Closable_Name   : aliased constant String := "closable";
   Resizable_Name  : aliased constant String := "resizable";
   Movable_Name    : aliased constant String := "movable";

   function Metadata (Kind : Surface_Kind) return Surface_Kind_Metadata is
     (case Kind is
        when Window =>
          (Stable_Name => Window_Name'Access,
           Top_Level => True,
           Modal_By_Kind => False),
        when Dialog =>
          (Stable_Name => Dialog_Name'Access,
           Top_Level => True,
           Modal_By_Kind => False),
        when Modal_Dialog =>
          (Stable_Name => Modal_Dialog_Name'Access,
           Top_Level => True,
           Modal_By_Kind => True),
        when Sheet =>
          (Stable_Name => Sheet_Name'Access,
           Top_Level => False,
           Modal_By_Kind => False),
        when Popup =>
          (Stable_Name => Popup_Name'Access,
           Top_Level => False,
           Modal_By_Kind => False),
        when Popover =>
          (Stable_Name => Popover_Name'Access,
           Top_Level => False,
           Modal_By_Kind => False),
        when Menu =>
          (Stable_Name => Menu_Name'Access,
           Top_Level => False,
           Modal_By_Kind => False),
        when Context_Menu =>
          (Stable_Name => Context_Menu_Name'Access,
           Top_Level => False,
           Modal_By_Kind => False),
        when Tooltip =>
          (Stable_Name => Tooltip_Name'Access,
           Top_Level => False,
           Modal_By_Kind => False),
        when Palette =>
          (Stable_Name => Palette_Name'Access,
           Top_Level => True,
           Modal_By_Kind => False),
        when Inspector =>
          (Stable_Name => Inspector_Name'Access,
           Top_Level => True,
           Modal_By_Kind => False),
        when Splash =>
          (Stable_Name => Splash_Name'Access,
           Top_Level => True,
           Modal_By_Kind => False),
        when Notification =>
          (Stable_Name => Notification_Name'Access,
           Top_Level => True,
           Modal_By_Kind => False),
        when Utility_Window =>
          (Stable_Name => Utility_Window_Name'Access,
           Top_Level => True,
           Modal_By_Kind => False),
        when Embedded_Surface =>
          (Stable_Name => Embedded_Surface_Name'Access,
           Top_Level => False,
           Modal_By_Kind => False));

   function Metadata
     (Flag : Surface_State_Flag)
      return Surface_State_Flag_Metadata is
     (case Flag is
        when Visible =>
          (Stable_Name => Visible_Name'Access,
           Operation_Capability => False),
        when Active =>
          (Stable_Name => Active_Name'Access,
           Operation_Capability => False),
        when Modal =>
          (Stable_Name => Modal_Name'Access,
           Operation_Capability => False),
        when Minimized =>
          (Stable_Name => Minimized_Name'Access,
           Operation_Capability => False),
        when Maximized =>
          (Stable_Name => Maximized_Name'Access,
           Operation_Capability => False),
        when Fullscreen =>
          (Stable_Name => Fullscreen_Name'Access,
           Operation_Capability => False),
        when Closable =>
          (Stable_Name => Closable_Name'Access,
           Operation_Capability => True),
        when Resizable =>
          (Stable_Name => Resizable_Name'Access,
           Operation_Capability => True),
        when Movable =>
          (Stable_Name => Movable_Name'Access,
           Operation_Capability => True));

   function Stable_Name (Kind : Surface_Kind) return String is
     (Metadata (Kind).Stable_Name.all);

   function Stable_Name (Flag : Surface_State_Flag) return String is
     (Metadata (Flag).Stable_Name.all);

   function Is_Top_Level_Kind (Kind : Surface_Kind) return Boolean is
     (A11y.Windows.Classification.Is_Top_Level_Kind (Kind))
   with SPARK_Mode => On;

   function Is_Top_Level (Kind : Surface_Kind) return Boolean is
     (Is_Top_Level_Kind (Kind))
   with SPARK_Mode => On;

   function Is_Modal_Kind (Kind : Surface_Kind) return Boolean is
     (A11y.Windows.Classification.Is_Modal_Kind (Kind))
   with SPARK_Mode => On;

   function Is_Modal (Item : Surface_Metadata) return Boolean is
     (A11y.Windows.Classification.Is_Modal_Surface (Item))
   with SPARK_Mode => On;

   function Is_Operation_State
     (Flag : Surface_State_Flag)
      return Boolean is
     (A11y.Windows.Classification.Is_Operation_State (Flag))
   with SPARK_Mode => On;

   function Has_State
     (State : Surface_State;
      Flag  : Surface_State_Flag)
      return Boolean is
     (A11y.Windows.Classification.Has_State (State, Flag))
   with SPARK_Mode => On;

   function State_Is_Coherent
     (State : Surface_State)
      return Boolean is
     (A11y.Windows.Classification.State_Is_Coherent (State))
   with SPARK_Mode => On;

   procedure Set_State
     (State : in out Surface_State;
      Flag  : Surface_State_Flag;
      Value : Boolean := True)
   with SPARK_Mode => On
   is
   begin
      case Flag is
         when Visible =>
            State.Visible := Value;
         when Active =>
            State.Active := Value;
         when Modal =>
            State.Modal := Value;
         when Minimized =>
            State.Minimized := Value;
         when Maximized =>
            State.Maximized := Value;
         when Fullscreen =>
            State.Fullscreen := Value;
         when Closable =>
            State.Closable := Value;
         when Resizable =>
            State.Resizable := Value;
         when Movable =>
            State.Movable := Value;
      end case;
   end Set_State;

   function Validate
     (Item : Surface_Metadata)
      return A11y.Results.Result
   with SPARK_Mode => On
   is
   begin
      return
        (Status =>
           (if State_Is_Coherent (Item.State)
            then A11y.Results.Success
            else A11y.Results.Invalid_State));
   end Validate;

   function Current_Surface_Safely
     (Self   : Surface_Provider'Class;
      Result : out A11y.Results.Result)
      return Surface_Metadata
   is
      Item : Surface_Metadata;
   begin
      Item := Self.Current_Surface;
      Result := Validate (Item);
      if A11y.Results.Failed (Result) then
         return (Kind  => Embedded_Surface,
                 State => (others => False));
      end if;
      return Item;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return (Kind  => Embedded_Surface,
                 State => (others => False));
   end Current_Surface_Safely;

end A11y.Windows;
