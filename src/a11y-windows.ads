with A11y.Results;

package A11y.Windows is

   use type A11y.Results.Status_Code;

   type Surface_Kind is
     (Window,
      Dialog,
      Modal_Dialog,
      Sheet,
      Popup,
      Popover,
      Menu,
      Context_Menu,
      Tooltip,
      Palette,
      Inspector,
      Splash,
      Notification,
      Utility_Window,
      Embedded_Surface);

   type Surface_Kind_Metadata is record
      Stable_Name   : access constant String;
      Top_Level     : Boolean := False;
      Modal_By_Kind : Boolean := False;
   end record;

   type Surface_State is record
      Visible     : Boolean := False;
      Active      : Boolean := False;
      Modal       : Boolean := False;
      Minimized   : Boolean := False;
      Maximized   : Boolean := False;
      Fullscreen  : Boolean := False;
      Closable    : Boolean := False;
      Resizable   : Boolean := False;
      Movable     : Boolean := False;
   end record;

   type Surface_State_Flag is
     (Visible,
      Active,
      Modal,
      Minimized,
      Maximized,
      Fullscreen,
      Closable,
      Resizable,
      Movable);

   type Surface_State_Flag_Metadata is record
      Stable_Name : access constant String;
      Operation_Capability : Boolean := False;
   end record;

   type Surface_Metadata is record
      Kind  : Surface_Kind := Window;
      State : Surface_State;
   end record;

   function Metadata (Kind : Surface_Kind) return Surface_Kind_Metadata;
   function Metadata
     (Flag : Surface_State_Flag)
      return Surface_State_Flag_Metadata;

   function Stable_Name (Kind : Surface_Kind) return String;
   function Stable_Name (Flag : Surface_State_Flag) return String;

   function Is_Top_Level_Kind (Kind : Surface_Kind) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Is_Top_Level_Kind'Result =
         (Kind in Window | Dialog | Modal_Dialog | Palette | Inspector |
                  Splash | Notification | Utility_Window);
   function Is_Top_Level (Kind : Surface_Kind) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Is_Top_Level'Result = Is_Top_Level_Kind (Kind);
   function Is_Modal_Kind (Kind : Surface_Kind) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Is_Modal_Kind'Result = (Kind = Modal_Dialog);
   function Is_Modal (Item : Surface_Metadata) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Is_Modal'Result =
         (Is_Modal_Kind (Item.Kind) or else Item.State.Modal);
   function Is_Operation_State
     (Flag : Surface_State_Flag)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Is_Operation_State'Result =
         (Flag in Closable | Resizable | Movable);
   function Has_State
     (State : Surface_State;
      Flag  : Surface_State_Flag)
      return Boolean
   with
     SPARK_Mode => On,
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
   function State_Is_Coherent
     (State : Surface_State)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       State_Is_Coherent'Result =
         ((not State.Active or else State.Visible)
          and then (not State.Active or else not State.Minimized)
          and then
            (not State.Minimized
             or else
               (not State.Maximized and then not State.Fullscreen))
          and then (not State.Maximized or else not State.Fullscreen));

   procedure Set_State
     (State : in out Surface_State;
      Flag  : Surface_State_Flag;
      Value : Boolean := True)
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Has_State (State, Flag) = Value
       and then
         (for all Other in Surface_State_Flag =>
            (if Other /= Flag
             then Has_State (State, Other) = Has_State (State'Old, Other)));

   function Validate
     (Item : Surface_Metadata)
      return A11y.Results.Result
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Validate'Result.Status =
         (if State_Is_Coherent (Item.State)
          then A11y.Results.Success
          else A11y.Results.Invalid_State);

   type Surface_Provider is limited interface;

   function Current_Surface
     (Self : Surface_Provider)
      return Surface_Metadata is abstract;

   function Current_Surface_Safely
     (Self   : Surface_Provider'Class;
      Result : out A11y.Results.Result)
      return Surface_Metadata;

end A11y.Windows;
