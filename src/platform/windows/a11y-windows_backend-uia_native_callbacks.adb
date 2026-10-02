with System.Address_To_Access_Conversions;
with Ada.Unchecked_Conversion;

with Ada.Strings.Unbounded;

with A11y.Windows_Backend.UIA_COM_Exports;
with A11y.Windows_Backend.UIA_Actions;
with A11y.Windows_Backend.UIA_ABI_Surface;
with A11y.Windows_Backend.UIA_Com_Providers;
with A11y.Windows_Backend.UIA_Mappings;
with A11y.Windows_Backend.UIA_Properties;
with A11y.Windows_Backend.UIA_Provider_Boundary;
with A11y.Windows_Backend.UIA_Surfaces;
with A11y.Windows_Backend.UIA_Values;
with A11y.Geometry;
with A11y.States;
with A11y.Native_Identity;
with A11y.Values;

package body A11y.Windows_Backend.UIA_Native_Callbacks is

   package Live renames A11y.Windows_Backend.UIA_COM_Live_Exports;
   package Native renames A11y.Windows_Backend.UIA_Native_Bridge;
   package Boundary renames A11y.Windows_Backend.UIA_Provider_Boundary;
   package Exports renames A11y.Windows_Backend.UIA_COM_Exports;
   package ABI renames A11y.Windows_Backend.UIA_ABI_Surface;
   package COM renames A11y.Windows_Backend.UIA_Com_Providers;
   package Object_Exports renames
     A11y.Windows_Backend.UIA_COM_Object_Exports;
   package Registry renames A11y.Windows_Backend.UIA_Provider_Registry;

   Native_Value_Kind_BSTR : constant Native.Native_UInt32 := 1;
   Native_Value_Kind_UInt32_SAFEARRAY : constant Native.Native_UInt32 := 2;
   Native_Value_Kind_UInt32 : constant Native.Native_UInt32 := 3;
   Native_Value_Kind_Boolean : constant Native.Native_UInt32 := 4;
   Native_Value_Kind_Not_Supported : constant Native.Native_UInt32 := 6;
   UIA_Bounding_Rectangle_Property_Id : constant Native.Native_UInt32 := 30_001;
   UIA_Control_Type_Property_Id : constant Native.Native_UInt32 := 30_003;
   UIA_Name_Property_Id : constant Native.Native_UInt32 := 30_005;
   UIA_Accelerator_Key_Property_Id : constant Native.Native_UInt32 := 30_006;
   UIA_Access_Key_Property_Id : constant Native.Native_UInt32 := 30_007;
   UIA_Has_Keyboard_Focus_Property_Id : constant Native.Native_UInt32 :=
     30_008;
   UIA_Is_Keyboard_Focusable_Property_Id : constant Native.Native_UInt32 :=
     30_009;
   UIA_Is_Enabled_Property_Id : constant Native.Native_UInt32 := 30_010;
   UIA_Automation_Id_Property_Id : constant Native.Native_UInt32 := 30_011;
   UIA_Help_Text_Property_Id : constant Native.Native_UInt32 := 30_013;
   UIA_Is_Password_Property_Id : constant Native.Native_UInt32 := 30_019;
   UIA_Is_Offscreen_Property_Id : constant Native.Native_UInt32 := 30_022;
   UIA_Orientation_Property_Id : constant Native.Native_UInt32 := 30_023;
   UIA_Is_Required_For_Form_Property_Id : constant Native.Native_UInt32 :=
     30_025;
   UIA_Position_In_Set_Property_Id : constant Native.Native_UInt32 := 30_152;
   UIA_Size_Of_Set_Property_Id : constant Native.Native_UInt32 := 30_153;
   UIA_Level_Property_Id : constant Native.Native_UInt32 := 30_154;
   UIA_Heading_Level_Property_Id : constant Native.Native_UInt32 := 30_173;
   UIA_Invoke_Pattern_Id : constant Native.Native_UInt32 := 10_000;
   UIA_Selection_Pattern_Id : constant Native.Native_UInt32 := 10_001;
   UIA_Value_Pattern_Id : constant Native.Native_UInt32 := 10_002;
   UIA_Range_Value_Pattern_Id : constant Native.Native_UInt32 := 10_003;
   UIA_Scroll_Pattern_Id : constant Native.Native_UInt32 := 10_004;
   UIA_Expand_Collapse_Pattern_Id : constant Native.Native_UInt32 := 10_005;
   UIA_Window_Pattern_Id : constant Native.Native_UInt32 := 10_009;
   UIA_Selection_Item_Pattern_Id : constant Native.Native_UInt32 := 10_010;
   UIA_Toggle_Pattern_Id : constant Native.Native_UInt32 := 10_015;
   UIA_Scroll_Item_Pattern_Id : constant Native.Native_UInt32 := 10_017;
   Native_Toggle_State : constant Native.Native_UInt32 := 1;
   Native_Expand_Collapse_State : constant Native.Native_UInt32 := 2;
   Max_UTF8_Copy          : constant Natural := 4_096;
   Max_UInt32_Array_Copy  : constant Natural := 32;

   type Frame_Words is
     array (Natural range 0 .. 7) of Native.Native_UInt64
   with Convention => C;

   type UTF8_Buffer_Words is
     array (Natural range 0 .. Max_UTF8_Copy - 1) of aliased Interfaces.C.char
   with Convention => C;

   type UInt32_Buffer_Words is
     array (Natural range 0 .. Max_UInt32_Array_Copy - 1)
       of aliased Native.Native_UInt32
   with Convention => C;

   package Frame_Conversions is
     new System.Address_To_Access_Conversions (Frame_Words);

   package UTF8_Buffer_Conversions is
     new System.Address_To_Access_Conversions (UTF8_Buffer_Words);

   package UInt32_Buffer_Conversions is
     new System.Address_To_Access_Conversions (UInt32_Buffer_Words);

   package Context_Conversions is
     new System.Address_To_Access_Conversions (Callback_Context);

   use type Native.Native_Int64;

   function To_Native_Int64 is new Ada.Unchecked_Conversion
     (Source => Native.Native_UInt64,
      Target => Native.Native_Int64);

   function To_Coordinate
     (Value : Native.Native_UInt64)
      return A11y.Geometry.Coordinate
   is
      Signed : constant Native.Native_Int64 := To_Native_Int64 (Value);
   begin
      return A11y.Geometry.Coordinate (Signed);
   exception
      when others =>
         return 0;
   end To_Coordinate;

   use type System.Address;
   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;
   use type A11y.Windows_Backend.UIA_Provider_Boundary.HRESULT_Status;
   use type A11y.Windows_Backend.UIA_Request_Router.Routed_Reply_Kind;
   use type A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method;
   use type COM.Provider_Interface;
   use type A11y.Values.Value_Kind;
   use type Frame_Conversions.Object_Pointer;
   use type UTF8_Buffer_Conversions.Object_Pointer;
   use type UInt32_Buffer_Conversions.Object_Pointer;
   use type Context_Conversions.Object_Pointer;

   function Error_Code
     (Status : A11y.Results.Status_Code)
      return Native.Native_UInt32
   is
   begin
      return
        Native.Native_UInt32
          (Exports.HRESULT_Code (Boundary.HResult_For (Status)));
   exception
      when others =>
         return 16#8000_4005#;
   end Error_Code;

   function Pattern_From_Native
     (Native_Pattern : Native.Native_UInt32;
      Pattern        : out A11y.Windows_Backend.UIA_Actions.UIA_Pattern)
      return Boolean
   is
   begin
      case Native_Pattern is
         when UIA_Invoke_Pattern_Id =>
            Pattern := A11y.Windows_Backend.UIA_Actions.Invoke;
         when UIA_Toggle_Pattern_Id =>
            Pattern := A11y.Windows_Backend.UIA_Actions.Toggle;
         when UIA_Expand_Collapse_Pattern_Id =>
            Pattern := A11y.Windows_Backend.UIA_Actions.Expand_Collapse;
         when UIA_Value_Pattern_Id =>
            Pattern := A11y.Windows_Backend.UIA_Actions.Value;
         when UIA_Range_Value_Pattern_Id =>
            Pattern := A11y.Windows_Backend.UIA_Actions.Range_Value;
         when UIA_Selection_Pattern_Id =>
            Pattern := A11y.Windows_Backend.UIA_Actions.Selection;
         when UIA_Selection_Item_Pattern_Id =>
            Pattern := A11y.Windows_Backend.UIA_Actions.Selection_Item;
         when UIA_Scroll_Pattern_Id | UIA_Scroll_Item_Pattern_Id =>
            Pattern := A11y.Windows_Backend.UIA_Actions.Scroll_Item;
         when UIA_Window_Pattern_Id =>
            Pattern := A11y.Windows_Backend.UIA_Actions.Window;
         when others =>
            Pattern := A11y.Windows_Backend.UIA_Actions.Invoke;
            return False;
      end case;

      return True;
   exception
      when others =>
         Pattern := A11y.Windows_Backend.UIA_Actions.Invoke;
         return False;
   end Pattern_From_Native;

   function Property_From_Native
     (Native_Property : Native.Native_UInt32;
      Property        : out A11y.Windows_Backend.UIA_Properties.Core_Property)
      return Boolean
   is
      package Props renames A11y.Windows_Backend.UIA_Properties;
   begin
      case Native_Property is
         when UIA_Name_Property_Id =>
            Property := Props.Name;
         when UIA_Control_Type_Property_Id =>
            Property := Props.Control_Type;
         when UIA_Automation_Id_Property_Id =>
            Property := Props.Automation_Id;
         when UIA_Help_Text_Property_Id =>
            Property := Props.Help_Text;
         when UIA_Accelerator_Key_Property_Id | UIA_Access_Key_Property_Id =>
            Property := Props.Keyboard_Shortcut;
         when UIA_Orientation_Property_Id =>
            Property := Props.Orientation;
         when UIA_Position_In_Set_Property_Id =>
            Property := Props.Position_In_Set;
         when UIA_Size_Of_Set_Property_Id =>
            Property := Props.Size_Of_Set;
         when UIA_Level_Property_Id =>
            Property := Props.Hierarchical_Level;
         when UIA_Heading_Level_Property_Id =>
            Property := Props.Heading_Level;
         when UIA_Is_Enabled_Property_Id =>
            Property := Props.Is_Enabled;
         when UIA_Has_Keyboard_Focus_Property_Id =>
            Property := Props.Has_Keyboard_Focus;
         when UIA_Is_Keyboard_Focusable_Property_Id =>
            Property := Props.Is_Keyboard_Focusable;
         when UIA_Is_Offscreen_Property_Id =>
            Property := Props.Is_Offscreen;
         when UIA_Is_Password_Property_Id =>
            Property := Props.Is_Password;
         when UIA_Is_Required_For_Form_Property_Id =>
            Property := Props.Is_Required_For_Form;
         when UIA_Bounding_Rectangle_Property_Id =>
            Property := Props.Bounding_Rectangle;
         when others =>
            Property := Props.Name;
            return False;
      end case;

      return True;
   exception
      when others =>
         Property := A11y.Windows_Backend.UIA_Properties.Name;
         return False;
   end Property_From_Native;

   function Native_Control_Type_Id
     (Control_Type : A11y.Windows_Backend.UIA_Mappings.UIA_Control_Type)
      return Native.Native_UInt32
   is
   begin
      return
        (case Control_Type is
           when A11y.Windows_Backend.UIA_Mappings.Button => 50_000,
           when A11y.Windows_Backend.UIA_Mappings.Check_Box => 50_002,
           when A11y.Windows_Backend.UIA_Mappings.Combo_Box => 50_003,
           when A11y.Windows_Backend.UIA_Mappings.Edit => 50_004,
           when A11y.Windows_Backend.UIA_Mappings.Hyperlink => 50_005,
           when A11y.Windows_Backend.UIA_Mappings.Image => 50_006,
           when A11y.Windows_Backend.UIA_Mappings.List_Item => 50_007,
           when A11y.Windows_Backend.UIA_Mappings.List => 50_008,
           when A11y.Windows_Backend.UIA_Mappings.Menu => 50_009,
           when A11y.Windows_Backend.UIA_Mappings.Menu_Bar => 50_010,
           when A11y.Windows_Backend.UIA_Mappings.Menu_Item => 50_011,
           when A11y.Windows_Backend.UIA_Mappings.Progress_Bar => 50_012,
           when A11y.Windows_Backend.UIA_Mappings.Radio_Button => 50_013,
           when A11y.Windows_Backend.UIA_Mappings.Scroll_Bar => 50_014,
           when A11y.Windows_Backend.UIA_Mappings.Slider => 50_015,
           when A11y.Windows_Backend.UIA_Mappings.Spinner => 50_016,
           when A11y.Windows_Backend.UIA_Mappings.Status_Bar => 50_017,
           when A11y.Windows_Backend.UIA_Mappings.Tab => 50_018,
           when A11y.Windows_Backend.UIA_Mappings.Tab_Item => 50_019,
           when A11y.Windows_Backend.UIA_Mappings.Text => 50_020,
           when A11y.Windows_Backend.UIA_Mappings.Tool_Bar => 50_021,
           when A11y.Windows_Backend.UIA_Mappings.Tool_Tip => 50_022,
           when A11y.Windows_Backend.UIA_Mappings.Tree => 50_023,
           when A11y.Windows_Backend.UIA_Mappings.Tree_Item => 50_024,
           when A11y.Windows_Backend.UIA_Mappings.Custom => 50_025,
           when A11y.Windows_Backend.UIA_Mappings.Window => 50_032,
           when A11y.Windows_Backend.UIA_Mappings.Pane => 50_033,
           when A11y.Windows_Backend.UIA_Mappings.Table => 50_036,
           when A11y.Windows_Backend.UIA_Mappings.Separator => 50_038);
   exception
      when others =>
         return 50_025;
   end Native_Control_Type_Id;

   function Dispatch_Interface_Frame_Callback
     (Frame   : access constant Native.Native_UInt64;
      Context : System.Address)
      return Native.Native_UInt32
   is
      Context_View : constant Context_Conversions.Object_Pointer :=
        Context_Conversions.To_Pointer (Context);
      Frame_View : Frame_Conversions.Object_Pointer;
      Request_Frame : Live.ABI_Interface_Frame;
      Reply : Boundary.Boundary_Reply;
   begin
      if Frame = null
        or else Context = System.Null_Address
        or else Context_View = null
        or else Context_View.Object_Table = null
        or else Context_View.Registry = null
        or else Context_View.Snapshots = null
      then
         return Error_Code (A11y.Results.Invalid_Argument);
      end if;

      Frame_View := Frame_Conversions.To_Pointer (Frame.all'Address);
      if Frame_View = null then
         return Error_Code (A11y.Results.Invalid_Argument);
      end if;

      Request_Frame :=
        (Session_Code      => Frame_View (0),
         Provider_Code     => Frame_View (1),
         Object_Token_Code => Frame_View (2),
         Interface_Code    => Interfaces.Unsigned_32 (Frame_View (3)),
         Method_Code       => Interfaces.Unsigned_32 (Frame_View (4)),
         Direction_Code    => Interfaces.Unsigned_32 (Frame_View (5)),
         Point_X           => To_Coordinate (Frame_View (6)),
         Point_Y           => To_Coordinate (Frame_View (7)));

      Reply :=
        Live.Dispatch_Interface_Frame_Access
          (Context_View.Object_Table.all,
           Request_Frame,
           Context_View.Registry.all,
           Context_View.Snapshots,
           Context_View.Last_Report);

      Context_View.Dispatched := True;
      Context_View.Last_Status := Reply.Status;
      Context_View.Last_HResult_Code :=
        Exports.HRESULT_Code (Reply.HResult);
      return Native.Native_UInt32 (Context_View.Last_HResult_Code);
   exception
      when others =>
         if Context /= System.Null_Address
           and then Context_Conversions.To_Pointer (Context) /= null
         then
            Context_Conversions.To_Pointer (Context).Last_Status :=
              A11y.Results.Internal_Error;
            Context_Conversions.To_Pointer (Context).Last_HResult_Code :=
              16#8000_4005#;
         end if;
         return 16#8000_4005#;
   end Dispatch_Interface_Frame_Callback;

   function Copy_Property_Value_Callback
     (Frame           : access constant Native.Native_UInt64;
      Native_Property : Native.Native_UInt32;
      Value_Kind      : access Native.Native_UInt32;
      UTF8_Buffer     : System.Address;
      UTF8_Capacity   : Native.Native_UInt32;
      UTF8_Used       : access Native.Native_UInt32;
      Context         : System.Address)
      return Native.Native_UInt32
   is
      Context_View : constant Context_Conversions.Object_Pointer :=
        Context_Conversions.To_Pointer (Context);
      Frame_View : Frame_Conversions.Object_Pointer;
      Buffer_View : UTF8_Buffer_Conversions.Object_Pointer;
      Request_Frame : Live.ABI_Interface_Frame;
      Report : Live.ABI_Interface_Frame_Report;
      Reply : Boundary.Boundary_Reply;
      Property : A11y.Windows_Backend.UIA_Properties.Core_Property;
      Request : A11y.Windows_Backend.UIA_Request_Router.Request;
      Routed : A11y.Windows_Backend.UIA_Request_Router.Routed_Reply;
   begin
      if Frame = null
        or else Value_Kind = null
        or else UTF8_Used = null
        or else UTF8_Buffer = System.Null_Address
        or else UTF8_Capacity = 0
        or else Context = System.Null_Address
        or else Context_View = null
        or else Context_View.Object_Table = null
        or else Context_View.Registry = null
        or else Context_View.Snapshots = null
      then
         return Error_Code (A11y.Results.Invalid_Argument);
      end if;

      Value_Kind.all := 0;
      UTF8_Used.all := 0;
      Frame_View := Frame_Conversions.To_Pointer (Frame.all'Address);
      Buffer_View := UTF8_Buffer_Conversions.To_Pointer (UTF8_Buffer);
      if Frame_View = null or else Buffer_View = null then
         return Error_Code (A11y.Results.Invalid_Argument);
      end if;

      Request_Frame :=
        (Session_Code      => Frame_View (0),
         Provider_Code     => Frame_View (1),
         Object_Token_Code => Frame_View (2),
         Interface_Code    => Interfaces.Unsigned_32 (Frame_View (3)),
         Method_Code       => Interfaces.Unsigned_32 (Frame_View (4)),
         Direction_Code    => Interfaces.Unsigned_32 (Frame_View (5)),
         Point_X           => 0,
         Point_Y           => 0);
      Reply :=
        Live.Dispatch_Interface_Frame_Access
          (Context_View.Object_Table.all,
           Request_Frame,
           Context_View.Registry.all,
           Context_View.Snapshots,
           Report);

      Context_View.Dispatched := True;
      Context_View.Last_Report := Report;
      Context_View.Last_Status := Reply.Status;
      Context_View.Last_HResult_Code := Exports.HRESULT_Code (Reply.HResult);

      if Reply.HResult /= Boundary.S_OK then
         return Native.Native_UInt32 (Context_View.Last_HResult_Code);
      elsif not Property_From_Native (Native_Property, Property)
      then
         Value_Kind.all := Native_Value_Kind_Not_Supported;
         return Native.Native_UInt32 (Exports.HRESULT_Code (Boundary.S_OK));
      end if;

      Request.Kind := A11y.Windows_Backend.UIA_Request_Router.Property_Query;
      Request.Property := Property;
      Routed :=
        A11y.Windows_Backend.UIA_Request_Router.Dispatch
          (Request, Context_View.Snapshots.all);
      Context_View.Last_Status := Routed.Status;
      if A11y.Results.Failed ((Status => Routed.Status)) then
         Context_View.Last_HResult_Code :=
           Exports.HRESULT_Code (Boundary.HResult_For (Routed.Status));
         return Native.Native_UInt32 (Context_View.Last_HResult_Code);
      end if;
      Context_View.Last_HResult_Code := Exports.HRESULT_Code (Boundary.S_OK);

      case Routed.Kind is
         when A11y.Windows_Backend.UIA_Request_Router.Property_String =>
            declare
               Text : constant String :=
                 Ada.Strings.Unbounded.To_String (Routed.Text);
               Capacity : constant Natural :=
                 Natural'Min (Natural (UTF8_Capacity), Max_UTF8_Copy);
               Copy_Length : constant Natural :=
                 Natural'Min (Text'Length, Capacity);
            begin
               if Text'Length > Capacity then
                  return Error_Code (A11y.Results.Resource_Limit);
               end if;

               if Copy_Length > 0 then
                  for Index in 0 .. Copy_Length - 1 loop
                     Buffer_View (Index) :=
                       Interfaces.C.char'Val
                         (Character'Pos (Text (Text'First + Index)));
                  end loop;
               end if;
               Value_Kind.all := Native_Value_Kind_BSTR;
               UTF8_Used.all := Native.Native_UInt32 (Copy_Length);
               return Native.Native_UInt32
                 (Exports.HRESULT_Code (Boundary.S_OK));
            end;
         when A11y.Windows_Backend.UIA_Request_Router.Property_Empty_String =>
            Value_Kind.all := Native_Value_Kind_BSTR;
            UTF8_Used.all := 0;
            return Native.Native_UInt32 (Exports.HRESULT_Code (Boundary.S_OK));
         when A11y.Windows_Backend.UIA_Request_Router.Property_Integer =>
            if Routed.Integer_Item < 0 then
               return Error_Code (A11y.Results.Invalid_Argument);
            end if;
            Value_Kind.all := Native_Value_Kind_UInt32;
            UTF8_Used.all := Native.Native_UInt32 (Routed.Integer_Item);
            return Native.Native_UInt32 (Exports.HRESULT_Code (Boundary.S_OK));
         when A11y.Windows_Backend.UIA_Request_Router.Property_Boolean =>
            Value_Kind.all := Native_Value_Kind_Boolean;
            UTF8_Used.all := (if Routed.Boolean_Item then 1 else 0);
            return Native.Native_UInt32 (Exports.HRESULT_Code (Boundary.S_OK));
         when A11y.Windows_Backend.UIA_Request_Router.Property_Control_Type =>
            Value_Kind.all := Native_Value_Kind_UInt32;
            UTF8_Used.all :=
              Native_Control_Type_Id (Routed.Control_Type);
            return Native.Native_UInt32 (Exports.HRESULT_Code (Boundary.S_OK));
         when A11y.Windows_Backend.UIA_Request_Router.Property_Not_Supported =>
            Value_Kind.all := Native_Value_Kind_Not_Supported;
            return Native.Native_UInt32 (Exports.HRESULT_Code (Boundary.S_OK));
         when others =>
            Value_Kind.all := Native_Value_Kind_Not_Supported;
            return Native.Native_UInt32 (Exports.HRESULT_Code (Boundary.S_OK));
      end case;
   exception
      when others =>
         if Context /= System.Null_Address
           and then Context_Conversions.To_Pointer (Context) /= null
         then
            Context_Conversions.To_Pointer (Context).Last_Status :=
              A11y.Results.Internal_Error;
            Context_Conversions.To_Pointer (Context).Last_HResult_Code :=
              16#8000_4005#;
         end if;
         return 16#8000_4005#;
   end Copy_Property_Value_Callback;

   function Copy_Runtime_Id_Callback
     (Frame      : access constant Native.Native_UInt64;
      Value_Kind : access Native.Native_UInt32;
      Items      : System.Address;
      Capacity   : Native.Native_UInt32;
      Used       : access Native.Native_UInt32;
      Context    : System.Address)
      return Native.Native_UInt32
   is
      Context_View : constant Context_Conversions.Object_Pointer :=
        Context_Conversions.To_Pointer (Context);
      Frame_View : Frame_Conversions.Object_Pointer;
      Buffer_View : UInt32_Buffer_Conversions.Object_Pointer;
      Request_Frame : Live.ABI_Interface_Frame;
      Report : Live.ABI_Interface_Frame_Report;
      Reply : Boundary.Boundary_Reply;
   begin
      if Frame = null
        or else Value_Kind = null
        or else Used = null
        or else Items = System.Null_Address
        or else Capacity < 3
        or else Context = System.Null_Address
        or else Context_View = null
        or else Context_View.Object_Table = null
        or else Context_View.Registry = null
        or else Context_View.Snapshots = null
      then
         return Error_Code (A11y.Results.Invalid_Argument);
      end if;

      Value_Kind.all := 0;
      Used.all := 0;
      Frame_View := Frame_Conversions.To_Pointer (Frame.all'Address);
      Buffer_View := UInt32_Buffer_Conversions.To_Pointer (Items);
      if Frame_View = null or else Buffer_View = null then
         return Error_Code (A11y.Results.Invalid_Argument);
      end if;

      Request_Frame :=
        (Session_Code      => Frame_View (0),
         Provider_Code     => Frame_View (1),
         Object_Token_Code => Frame_View (2),
         Interface_Code    => Interfaces.Unsigned_32 (Frame_View (3)),
         Method_Code       => Interfaces.Unsigned_32 (Frame_View (4)),
         Direction_Code    => Interfaces.Unsigned_32 (Frame_View (5)),
         Point_X           => 0,
         Point_Y           => 0);
      Reply :=
        Live.Dispatch_Interface_Frame_Access
          (Context_View.Object_Table.all,
           Request_Frame,
           Context_View.Registry.all,
           Context_View.Snapshots,
           Report);

      Context_View.Dispatched := True;
      Context_View.Last_Report := Report;
      Context_View.Last_Status := Reply.Status;
      Context_View.Last_HResult_Code := Exports.HRESULT_Code (Reply.HResult);

      if Reply.HResult /= Boundary.S_OK then
         return Native.Native_UInt32 (Context_View.Last_HResult_Code);
      elsif Reply.Routed /= A11y.Windows_Backend.UIA_Request_Router.Runtime_Id
      then
         return Error_Code (A11y.Results.Unsupported_Property);
      end if;

      Buffer_View (0) :=
        Native.Native_UInt32 (Reply.Payload.Id.Session_Component);
      Buffer_View (1) :=
        Native.Native_UInt32 (Reply.Payload.Id.Root_Component);
      Buffer_View (2) :=
        Native.Native_UInt32 (Reply.Payload.Id.Node_Component);
      Value_Kind.all := Native_Value_Kind_UInt32_SAFEARRAY;
      Used.all := 3;
      return Native.Native_UInt32 (Exports.HRESULT_Code (Boundary.S_OK));
   exception
      when others =>
         if Context /= System.Null_Address
           and then Context_Conversions.To_Pointer (Context) /= null
         then
            Context_Conversions.To_Pointer (Context).Last_Status :=
              A11y.Results.Internal_Error;
            Context_Conversions.To_Pointer (Context).Last_HResult_Code :=
              16#8000_4005#;
         end if;
         return 16#8000_4005#;
   end Copy_Runtime_Id_Callback;

   function Copy_Bounding_Rectangle_Callback
     (Frame   : access constant Native.Native_UInt64;
      Left    : access Interfaces.C.double;
      Top     : access Interfaces.C.double;
      Width   : access Interfaces.C.double;
      Height  : access Interfaces.C.double;
      Context : System.Address)
      return Native.Native_UInt32
   is
      Context_View : constant Context_Conversions.Object_Pointer :=
        Context_Conversions.To_Pointer (Context);
      Frame_View : Frame_Conversions.Object_Pointer;
      Request_Frame : Live.ABI_Interface_Frame;
      Report : Live.ABI_Interface_Frame_Report;
      Reply : Boundary.Boundary_Reply;
   begin
      if Frame = null
        or else Left = null
        or else Top = null
        or else Width = null
        or else Height = null
        or else Context = System.Null_Address
        or else Context_View = null
        or else Context_View.Object_Table = null
        or else Context_View.Registry = null
        or else Context_View.Snapshots = null
      then
         return Error_Code (A11y.Results.Invalid_Argument);
      end if;

      Left.all := 0.0;
      Top.all := 0.0;
      Width.all := 0.0;
      Height.all := 0.0;
      Frame_View := Frame_Conversions.To_Pointer (Frame.all'Address);
      if Frame_View = null then
         return Error_Code (A11y.Results.Invalid_Argument);
      end if;

      Request_Frame :=
        (Session_Code      => Frame_View (0),
         Provider_Code     => Frame_View (1),
         Object_Token_Code => Frame_View (2),
         Interface_Code    => Interfaces.Unsigned_32 (Frame_View (3)),
         Method_Code       => Interfaces.Unsigned_32 (Frame_View (4)),
         Direction_Code    => Interfaces.Unsigned_32 (Frame_View (5)),
         Point_X           => 0,
         Point_Y           => 0);
      Reply :=
        Live.Dispatch_Interface_Frame_Access
          (Context_View.Object_Table.all,
           Request_Frame,
           Context_View.Registry.all,
           Context_View.Snapshots,
           Report);

      Context_View.Dispatched := True;
      Context_View.Last_Report := Report;
      Context_View.Last_Status := Reply.Status;
      Context_View.Last_HResult_Code := Exports.HRESULT_Code (Reply.HResult);

      if Reply.HResult /= Boundary.S_OK then
         return Native.Native_UInt32 (Context_View.Last_HResult_Code);
      elsif Reply.Routed /=
        A11y.Windows_Backend.UIA_Request_Router.Property_Rectangle
      then
         return Error_Code (A11y.Results.Unsupported_Property);
      end if;

      Left.all := Interfaces.C.double (Reply.Payload.Bounds.Origin.X);
      Top.all := Interfaces.C.double (Reply.Payload.Bounds.Origin.Y);
      Width.all := Interfaces.C.double (Reply.Payload.Bounds.Extent.Width);
      Height.all := Interfaces.C.double (Reply.Payload.Bounds.Extent.Height);
      return Native.Native_UInt32 (Exports.HRESULT_Code (Boundary.S_OK));
   exception
      when others =>
         if Context /= System.Null_Address
           and then Context_Conversions.To_Pointer (Context) /= null
         then
            Context_Conversions.To_Pointer (Context).Last_Status :=
              A11y.Results.Internal_Error;
            Context_Conversions.To_Pointer (Context).Last_HResult_Code :=
              16#8000_4005#;
         end if;
         return 16#8000_4005#;
   end Copy_Bounding_Rectangle_Callback;

   function Copy_Boolean_Callback
     (Frame   : access constant Native.Native_UInt64;
      Value   : access Native.Native_UInt32;
      Context : System.Address)
      return Native.Native_UInt32
   is
      Context_View : constant Context_Conversions.Object_Pointer :=
        Context_Conversions.To_Pointer (Context);
      Frame_View : Frame_Conversions.Object_Pointer;
      Request_Frame : Live.ABI_Interface_Frame;
      Report : Live.ABI_Interface_Frame_Report;
      Reply : Boundary.Boundary_Reply;
   begin
      if Frame = null
        or else Value = null
        or else Context = System.Null_Address
        or else Context_View = null
        or else Context_View.Object_Table = null
        or else Context_View.Registry = null
        or else Context_View.Snapshots = null
      then
         return Error_Code (A11y.Results.Invalid_Argument);
      end if;

      Value.all := 0;
      Frame_View := Frame_Conversions.To_Pointer (Frame.all'Address);
      if Frame_View = null then
         return Error_Code (A11y.Results.Invalid_Argument);
      end if;

      Request_Frame :=
        (Session_Code      => Frame_View (0),
         Provider_Code     => Frame_View (1),
         Object_Token_Code => Frame_View (2),
         Interface_Code    => Interfaces.Unsigned_32 (Frame_View (3)),
         Method_Code       => Interfaces.Unsigned_32 (Frame_View (4)),
         Direction_Code    => Interfaces.Unsigned_32 (Frame_View (5)),
         Point_X           => 0,
         Point_Y           => 0);
      Reply :=
        Live.Dispatch_Interface_Frame_Access
          (Context_View.Object_Table.all,
           Request_Frame,
           Context_View.Registry.all,
           Context_View.Snapshots,
           Report);

      Context_View.Dispatched := True;
      Context_View.Last_Report := Report;
      Context_View.Last_Status := Reply.Status;
      Context_View.Last_HResult_Code := Exports.HRESULT_Code (Reply.HResult);

      if Reply.HResult /= Boundary.S_OK then
         return Native.Native_UInt32 (Context_View.Last_HResult_Code);
      elsif Reply.Routed /=
        A11y.Windows_Backend.UIA_Request_Router.Selection_Boolean
      then
         return Error_Code (A11y.Results.Unsupported_Property);
      end if;

      Value.all := (if Reply.Payload.Boolean_Item then 1 else 0);
      return Native.Native_UInt32 (Exports.HRESULT_Code (Boundary.S_OK));
   exception
      when others =>
         if Context /= System.Null_Address
           and then Context_Conversions.To_Pointer (Context) /= null
         then
            Context_Conversions.To_Pointer (Context).Last_Status :=
              A11y.Results.Internal_Error;
            Context_Conversions.To_Pointer (Context).Last_HResult_Code :=
              16#8000_4005#;
         end if;
         return 16#8000_4005#;
   end Copy_Boolean_Callback;

   function Check_Pattern_Supported_Callback
     (Frame          : access constant Native.Native_UInt64;
      Native_Pattern : Native.Native_UInt32;
      Supported      : access Native.Native_UInt32;
      Context        : System.Address)
      return Native.Native_UInt32
   is
      Context_View : constant Context_Conversions.Object_Pointer :=
        Context_Conversions.To_Pointer (Context);
      Frame_View : Frame_Conversions.Object_Pointer;
      Request_Frame : Live.ABI_Interface_Frame;
      Report : Live.ABI_Interface_Frame_Report;
      Reply : Boundary.Boundary_Reply;
      Pattern : A11y.Windows_Backend.UIA_Actions.UIA_Pattern;
   begin
      if Frame = null
        or else Supported = null
        or else Context = System.Null_Address
        or else Context_View = null
        or else Context_View.Object_Table = null
        or else Context_View.Registry = null
        or else Context_View.Snapshots = null
      then
         return Error_Code (A11y.Results.Invalid_Argument);
      end if;

      Supported.all := 0;
      if not Pattern_From_Native (Native_Pattern, Pattern) then
         return Error_Code (A11y.Results.Unsupported_Capability);
      end if;

      Frame_View := Frame_Conversions.To_Pointer (Frame.all'Address);
      if Frame_View = null then
         return Error_Code (A11y.Results.Invalid_Argument);
      end if;

      Request_Frame :=
        (Session_Code      => Frame_View (0),
         Provider_Code     => Frame_View (1),
         Object_Token_Code => Frame_View (2),
         Interface_Code    => Interfaces.Unsigned_32 (Frame_View (3)),
         Method_Code       => Interfaces.Unsigned_32 (Frame_View (4)),
         Direction_Code    => 0,
         Point_X           => 0,
         Point_Y           => 0);
      Reply :=
        Live.Dispatch_Interface_Frame_Access
          (Context_View.Object_Table.all,
           Request_Frame,
           Context_View.Registry.all,
           Context_View.Snapshots,
           Report);

      Context_View.Dispatched := True;
      Context_View.Last_Report := Report;
      Context_View.Last_Status := Reply.Status;
      Context_View.Last_HResult_Code := Exports.HRESULT_Code (Reply.HResult);

      if Reply.HResult /= Boundary.S_OK then
         return Native.Native_UInt32 (Context_View.Last_HResult_Code);
      elsif Reply.Routed /= A11y.Windows_Backend.UIA_Request_Router.Pattern_Set
      then
         return Error_Code (A11y.Results.Unsupported_Property);
      end if;

      Supported.all := (if Reply.Payload.Patterns (Pattern) then 1 else 0);
      return Native.Native_UInt32 (Exports.HRESULT_Code (Boundary.S_OK));
   exception
      when others =>
         if Context /= System.Null_Address
           and then Context_Conversions.To_Pointer (Context) /= null
         then
            Context_Conversions.To_Pointer (Context).Last_Status :=
              A11y.Results.Internal_Error;
            Context_Conversions.To_Pointer (Context).Last_HResult_Code :=
              16#8000_4005#;
         end if;
         return 16#8000_4005#;
   end Check_Pattern_Supported_Callback;

   function Copy_Pattern_State_Callback
     (Frame             : access constant Native.Native_UInt64;
      Native_State_Kind : Native.Native_UInt32;
      State             : access Native.Native_UInt32;
      Context           : System.Address)
      return Native.Native_UInt32
   is
      Context_View : constant Context_Conversions.Object_Pointer :=
        Context_Conversions.To_Pointer (Context);
      Frame_View : Frame_Conversions.Object_Pointer;
      Request_Frame : Live.ABI_Interface_Frame;
      Report : Live.ABI_Interface_Frame_Report;
      Reply : Boundary.Boundary_Reply;
      Effective_States : A11y.States.State_Set;
   begin
      if Frame = null
        or else State = null
        or else Context = System.Null_Address
        or else Context_View = null
        or else Context_View.Object_Table = null
        or else Context_View.Registry = null
        or else Context_View.Snapshots = null
      then
         return Error_Code (A11y.Results.Invalid_Argument);
      end if;

      State.all := 0;
      if Native_State_Kind not in
        Native_Toggle_State | Native_Expand_Collapse_State
      then
         return Error_Code (A11y.Results.Unsupported_Property);
      end if;

      Frame_View := Frame_Conversions.To_Pointer (Frame.all'Address);
      if Frame_View = null then
         return Error_Code (A11y.Results.Invalid_Argument);
      end if;

      Request_Frame :=
        (Session_Code      => Frame_View (0),
         Provider_Code     => Frame_View (1),
         Object_Token_Code => Frame_View (2),
         Interface_Code    => Interfaces.Unsigned_32 (Frame_View (3)),
         Method_Code       => Interfaces.Unsigned_32 (Frame_View (4)),
         Direction_Code    => 0,
         Point_X           => 0,
         Point_Y           => 0);
      Reply :=
        Live.Dispatch_Interface_Frame_Access
          (Context_View.Object_Table.all,
           Request_Frame,
           Context_View.Registry.all,
           Context_View.Snapshots,
           Report);

      Context_View.Dispatched := True;
      Context_View.Last_Report := Report;
      Context_View.Last_Status := Reply.Status;
      Context_View.Last_HResult_Code := Exports.HRESULT_Code (Reply.HResult);

      if Reply.HResult /= Boundary.S_OK then
         return Native.Native_UInt32 (Context_View.Last_HResult_Code);
      end if;

      Effective_States :=
        A11y.States.Derive
          (Context_View.Snapshots.Properties.States,
           Context_View.Snapshots.Properties.Role,
           Context_View.Snapshots.Properties.Capabilities);

      if Native_State_Kind = Native_Toggle_State then
         if Effective_States (A11y.States.Indeterminate) then
            State.all := 2;
         elsif Effective_States (A11y.States.Checked) then
            State.all := 1;
         else
            State.all := 0;
         end if;
      elsif Effective_States (A11y.States.Expanded) then
         State.all := 1;
      else
         State.all := 0;
      end if;

      return Native.Native_UInt32 (Exports.HRESULT_Code (Boundary.S_OK));
   exception
      when others =>
         if Context /= System.Null_Address
           and then Context_Conversions.To_Pointer (Context) /= null
         then
            Context_Conversions.To_Pointer (Context).Last_Status :=
              A11y.Results.Internal_Error;
            Context_Conversions.To_Pointer (Context).Last_HResult_Code :=
              16#8000_4005#;
         end if;
         return 16#8000_4005#;
   end Copy_Pattern_State_Callback;

   function Dispatch_Range_Value_Set_Callback
     (Frame   : access constant Native.Native_UInt64;
      Value   : Interfaces.C.double;
      Context : System.Address)
      return Native.Native_UInt32
   is
      Context_View : constant Context_Conversions.Object_Pointer :=
        Context_Conversions.To_Pointer (Context);
      Frame_View : Frame_Conversions.Object_Pointer;
      Session : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Provider : Registry.Provider_Id := Registry.No_Provider;
      Token : Object_Exports.COM_Object_Token := Object_Exports.No_COM_Object;
      Requested : COM.Provider_Interface := COM.Unsupported_Interface;
      Method : ABI.UIA_ABI_Method := ABI.IUnknown_Query_Interface;
      Decode_Result : A11y.Results.Result;
      Query_Report : Live.Interface_Query_Report;
      Request : Boundary.Boundary_Request;
      Reply : Boundary.Boundary_Reply;
      Native_Value : constant Long_Float := Long_Float (Value);
   begin
      if Frame = null
        or else Context = System.Null_Address
        or else Context_View = null
        or else Context_View.Object_Table = null
        or else Context_View.Registry = null
        or else Context_View.Snapshots = null
      then
         return Error_Code (A11y.Results.Invalid_Argument);
      end if;

      Frame_View := Frame_Conversions.To_Pointer (Frame.all'Address);
      if Frame_View = null
        or else Frame_View (0) > Native.Native_UInt64 (Natural'Last)
        or else Frame_View (1) > Native.Native_UInt64 (Natural'Last)
        or else Frame_View (2) > Native.Native_UInt64 (Natural'Last)
        or else Frame_View (5) /= 0
      then
         return Error_Code (A11y.Results.Invalid_Argument);
      end if;

      Session :=
        A11y.Native_Identity.From_Natural (Natural (Frame_View (0)));
      Provider := Registry.From_Natural (Natural (Frame_View (1)));
      Token := Object_Exports.From_Natural (Natural (Frame_View (2)));
      if not A11y.Native_Identity.Is_Valid (Session)
        or else not Registry.Is_Valid (Provider)
        or else not Object_Exports.Is_Valid (Token)
      then
         return Error_Code (A11y.Results.Node_Unavailable);
      end if;

      Requested :=
        Live.Interface_From_Code
          (Interfaces.Unsigned_32 (Frame_View (3)), Decode_Result);
      if A11y.Results.Failed (Decode_Result) then
         return Error_Code (Decode_Result.Status);
      elsif Requested /= COM.Raw_Element_Provider_Simple then
         return Error_Code (A11y.Results.Unsupported_Capability);
      end if;

      Method :=
        ABI.Method_From_Code
          (Interfaces.Unsigned_32 (Frame_View (4)), Decode_Result);
      if A11y.Results.Failed (Decode_Result) then
         return Error_Code (Decode_Result.Status);
      elsif Method /= ABI.Range_Value_Provider_Set_Value then
         return Error_Code (A11y.Results.Unsupported_Capability);
      end if;

      Live.Query_Interface
        (Context_View.Object_Table.all,
         Token,
         Session,
         Provider,
         Requested,
         Query_Report);
      if not Query_Report.Object_Resolved
        or else not Query_Report.Query.Supported
        or else not Query_Report.Reference.Present
      then
         return Error_Code (Query_Report.Status);
      end if;

      Request.Kind := Boundary.Set_Value;
      Request.Has_Native_Identity := True;
      Request.Native_Node_Component :=
        Query_Report.Object_Report.Descriptor.Native_Node_Component;
      if Context_View.Snapshots.Value.Metadata.Current.Kind =
        A11y.Values.Integer_Value
        and then Native_Value >= Long_Float (Long_Long_Integer'First)
        and then Native_Value <= Long_Float (Long_Long_Integer'Last)
      then
         declare
            Integer_Value : constant Long_Long_Integer :=
              Long_Long_Integer (Native_Value);
         begin
            if Long_Float (Integer_Value) = Native_Value then
               Request.Requested_Value := A11y.Values.Integer (Integer_Value);
            else
               Request.Requested_Value := A11y.Values.Floating (Native_Value);
            end if;
         end;
      else
         Request.Requested_Value := A11y.Values.Floating (Native_Value);
      end if;

      Reply :=
        Boundary.Dispatch_Registered_Native_Request
          (Context_View.Registry.all,
           Session,
           Provider,
           Requested,
           Request,
           Context_View.Snapshots.all);

      Context_View.Dispatched := True;
      Context_View.Last_Status := Reply.Status;
      Context_View.Last_HResult_Code := Exports.HRESULT_Code (Reply.HResult);
      return Native.Native_UInt32 (Context_View.Last_HResult_Code);
   exception
      when others =>
         if Context /= System.Null_Address
           and then Context_Conversions.To_Pointer (Context) /= null
         then
            Context_Conversions.To_Pointer (Context).Last_Status :=
              A11y.Results.Internal_Error;
            Context_Conversions.To_Pointer (Context).Last_HResult_Code :=
              16#8000_4005#;
         end if;
         return 16#8000_4005#;
   end Dispatch_Range_Value_Set_Callback;

   function Copy_Range_Value_Query_Callback
     (Frame         : access constant Native.Native_UInt64;
      Numeric_Value : access Interfaces.C.double;
      Boolean_Value : access Native.Native_UInt32;
      Context       : System.Address)
      return Native.Native_UInt32
   is
      Context_View : constant Context_Conversions.Object_Pointer :=
        Context_Conversions.To_Pointer (Context);
      Frame_View : Frame_Conversions.Object_Pointer;
      Session : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Provider : Registry.Provider_Id := Registry.No_Provider;
      Token : Object_Exports.COM_Object_Token := Object_Exports.No_COM_Object;
      Requested : COM.Provider_Interface := COM.Unsupported_Interface;
      Method : ABI.UIA_ABI_Method := ABI.IUnknown_Query_Interface;
      Decode_Result : A11y.Results.Result;
      Query_Report : Live.Interface_Query_Report;
      Request : Boundary.Boundary_Request;
      Reply : Boundary.Boundary_Reply;
   begin
      if Frame = null
        or else Numeric_Value = null
        or else Boolean_Value = null
        or else Context = System.Null_Address
        or else Context_View = null
        or else Context_View.Object_Table = null
        or else Context_View.Registry = null
        or else Context_View.Snapshots = null
      then
         return Error_Code (A11y.Results.Invalid_Argument);
      end if;

      Numeric_Value.all := 0.0;
      Boolean_Value.all := 0;
      Frame_View := Frame_Conversions.To_Pointer (Frame.all'Address);
      if Frame_View = null
        or else Frame_View (0) > Native.Native_UInt64 (Natural'Last)
        or else Frame_View (1) > Native.Native_UInt64 (Natural'Last)
        or else Frame_View (2) > Native.Native_UInt64 (Natural'Last)
        or else Frame_View (5) /= 0
      then
         return Error_Code (A11y.Results.Invalid_Argument);
      end if;

      Session :=
        A11y.Native_Identity.From_Natural (Natural (Frame_View (0)));
      Provider := Registry.From_Natural (Natural (Frame_View (1)));
      Token := Object_Exports.From_Natural (Natural (Frame_View (2)));
      if not A11y.Native_Identity.Is_Valid (Session)
        or else not Registry.Is_Valid (Provider)
        or else not Object_Exports.Is_Valid (Token)
      then
         return Error_Code (A11y.Results.Node_Unavailable);
      end if;

      Requested :=
        Live.Interface_From_Code
          (Interfaces.Unsigned_32 (Frame_View (3)), Decode_Result);
      if A11y.Results.Failed (Decode_Result) then
         return Error_Code (Decode_Result.Status);
      elsif Requested /= COM.Raw_Element_Provider_Simple then
         return Error_Code (A11y.Results.Unsupported_Capability);
      end if;

      Method :=
        ABI.Method_From_Code
          (Interfaces.Unsigned_32 (Frame_View (4)), Decode_Result);
      if A11y.Results.Failed (Decode_Result) then
         return Error_Code (Decode_Result.Status);
      end if;

      Live.Query_Interface
        (Context_View.Object_Table.all,
         Token,
         Session,
         Provider,
         Requested,
         Query_Report);
      if not Query_Report.Object_Resolved
        or else not Query_Report.Query.Supported
        or else not Query_Report.Reference.Present
      then
         return Error_Code (Query_Report.Status);
      end if;

      Request.Kind := Boundary.Get_Value;
      Request.Has_Native_Identity := True;
      Request.Native_Node_Component :=
        Query_Report.Object_Report.Descriptor.Native_Node_Component;
      case Method is
         when ABI.Range_Value_Provider_Get_Value =>
            Request.Value :=
              A11y.Windows_Backend.UIA_Values.Current_Value;
         when ABI.Range_Value_Provider_Get_Is_Read_Only =>
            Request.Value :=
              A11y.Windows_Backend.UIA_Values.Is_Read_Only;
         when ABI.Range_Value_Provider_Get_Maximum =>
            Request.Value :=
              A11y.Windows_Backend.UIA_Values.Maximum_Value;
         when ABI.Range_Value_Provider_Get_Minimum =>
            Request.Value :=
              A11y.Windows_Backend.UIA_Values.Minimum_Value;
         when ABI.Range_Value_Provider_Get_Large_Change =>
            Request.Value :=
              A11y.Windows_Backend.UIA_Values.Large_Increment;
         when ABI.Range_Value_Provider_Get_Small_Change =>
            Request.Value :=
              A11y.Windows_Backend.UIA_Values.Small_Increment;
         when others =>
            return Error_Code (A11y.Results.Unsupported_Capability);
      end case;

      Reply :=
        Boundary.Dispatch_Registered_Native_Request
          (Context_View.Registry.all,
           Session,
           Provider,
           Requested,
           Request,
           Context_View.Snapshots.all);

      Context_View.Dispatched := True;
      Context_View.Last_Status := Reply.Status;
      Context_View.Last_HResult_Code := Exports.HRESULT_Code (Reply.HResult);
      if Reply.HResult /= Boundary.S_OK then
         return Native.Native_UInt32 (Context_View.Last_HResult_Code);
      elsif Method = ABI.Range_Value_Provider_Get_Is_Read_Only then
         if Reply.Routed /=
           A11y.Windows_Backend.UIA_Request_Router.Value_Boolean
         then
            return Error_Code (A11y.Results.Unsupported_Property);
         end if;
         Boolean_Value.all := (if Reply.Payload.Boolean_Item then 1 else 0);
      else
         if Reply.Routed /=
           A11y.Windows_Backend.UIA_Request_Router.Value_Float
         then
            return Error_Code (A11y.Results.Unsupported_Property);
         end if;
         Numeric_Value.all := Interfaces.C.double (Reply.Payload.Float_Item);
      end if;

      return Native.Native_UInt32 (Context_View.Last_HResult_Code);
   exception
      when others =>
         if Context /= System.Null_Address
           and then Context_Conversions.To_Pointer (Context) /= null
         then
            Context_Conversions.To_Pointer (Context).Last_Status :=
              A11y.Results.Internal_Error;
            Context_Conversions.To_Pointer (Context).Last_HResult_Code :=
              16#8000_4005#;
         end if;
         return 16#8000_4005#;
   end Copy_Range_Value_Query_Callback;

   function Copy_Window_Query_Callback
     (Frame   : access constant Native.Native_UInt64;
      Value   : access Native.Native_UInt32;
      Context : System.Address)
      return Native.Native_UInt32
   is
      Context_View : constant Context_Conversions.Object_Pointer :=
        Context_Conversions.To_Pointer (Context);
      Frame_View : Frame_Conversions.Object_Pointer;
      Session : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Provider : Registry.Provider_Id := Registry.No_Provider;
      Token : Object_Exports.COM_Object_Token := Object_Exports.No_COM_Object;
      Requested : COM.Provider_Interface := COM.Unsupported_Interface;
      Method : ABI.UIA_ABI_Method := ABI.IUnknown_Query_Interface;
      Decode_Result : A11y.Results.Result;
      Query_Report : Live.Interface_Query_Report;
      Request : Boundary.Boundary_Request;
      Reply : Boundary.Boundary_Reply;
   begin
      if Frame = null
        or else Value = null
        or else Context = System.Null_Address
        or else Context_View = null
        or else Context_View.Object_Table = null
        or else Context_View.Registry = null
        or else Context_View.Snapshots = null
      then
         return Error_Code (A11y.Results.Invalid_Argument);
      end if;

      Value.all := 0;
      Frame_View := Frame_Conversions.To_Pointer (Frame.all'Address);
      if Frame_View = null
        or else Frame_View (0) > Native.Native_UInt64 (Natural'Last)
        or else Frame_View (1) > Native.Native_UInt64 (Natural'Last)
        or else Frame_View (2) > Native.Native_UInt64 (Natural'Last)
        or else Frame_View (5) /= 0
      then
         return Error_Code (A11y.Results.Invalid_Argument);
      end if;

      Session :=
        A11y.Native_Identity.From_Natural (Natural (Frame_View (0)));
      Provider := Registry.From_Natural (Natural (Frame_View (1)));
      Token := Object_Exports.From_Natural (Natural (Frame_View (2)));
      if not A11y.Native_Identity.Is_Valid (Session)
        or else not Registry.Is_Valid (Provider)
        or else not Object_Exports.Is_Valid (Token)
      then
         return Error_Code (A11y.Results.Node_Unavailable);
      end if;

      Requested :=
        Live.Interface_From_Code
          (Interfaces.Unsigned_32 (Frame_View (3)), Decode_Result);
      if A11y.Results.Failed (Decode_Result) then
         return Error_Code (Decode_Result.Status);
      elsif Requested /= COM.Raw_Element_Provider_Simple then
         return Error_Code (A11y.Results.Unsupported_Capability);
      end if;

      Method :=
        ABI.Method_From_Code
          (Interfaces.Unsigned_32 (Frame_View (4)), Decode_Result);
      if A11y.Results.Failed (Decode_Result) then
         return Error_Code (Decode_Result.Status);
      end if;

      Live.Query_Interface
        (Context_View.Object_Table.all,
         Token,
         Session,
         Provider,
         Requested,
         Query_Report);
      if not Query_Report.Object_Resolved
        or else not Query_Report.Query.Supported
        or else not Query_Report.Reference.Present
      then
         return Error_Code (Query_Report.Status);
      end if;

      Request.Kind := Boundary.Get_Surface;
      Request.Has_Native_Identity := True;
      Request.Native_Node_Component :=
        Query_Report.Object_Report.Descriptor.Native_Node_Component;
      case Method is
         when ABI.Window_Provider_Get_Can_Maximize =>
            Request.Surface :=
              A11y.Windows_Backend.UIA_Surfaces.Can_Resize;
         when ABI.Window_Provider_Get_Can_Minimize =>
            Request.Surface :=
              A11y.Windows_Backend.UIA_Surfaces.Is_Top_Level;
         when ABI.Window_Provider_Get_Is_Modal =>
            Request.Surface :=
              A11y.Windows_Backend.UIA_Surfaces.Is_Modal;
         when ABI.Window_Provider_Get_Window_Visual_State =>
            Request.Surface :=
              A11y.Windows_Backend.UIA_Surfaces.Is_Maximized;
         when ABI.Window_Provider_Get_Window_Interaction_State =>
            Request.Surface :=
              A11y.Windows_Backend.UIA_Surfaces.Is_Active;
         when others =>
            return Error_Code (A11y.Results.Unsupported_Capability);
      end case;

      Reply :=
        Boundary.Dispatch_Registered_Native_Request
          (Context_View.Registry.all,
           Session,
           Provider,
           Requested,
           Request,
           Context_View.Snapshots.all);

      Context_View.Dispatched := True;
      Context_View.Last_Status := Reply.Status;
      Context_View.Last_HResult_Code := Exports.HRESULT_Code (Reply.HResult);
      if Reply.HResult /= Boundary.S_OK then
         return Native.Native_UInt32 (Context_View.Last_HResult_Code);
      elsif Reply.Routed /=
        A11y.Windows_Backend.UIA_Request_Router.Surface_Boolean
      then
         return Error_Code (A11y.Results.Unsupported_Property);
      end if;

      case Method is
         when ABI.Window_Provider_Get_Window_Visual_State =>
            -- UIA WindowVisualState: Normal=0, Maximized=1, Minimized=2.
            if Context_View.Snapshots.Surface.Metadata.State.Maximized then
               Value.all := 1;
            elsif Context_View.Snapshots.Surface.Metadata.State.Minimized then
               Value.all := 2;
            else
               Value.all := 0;
            end if;
         when ABI.Window_Provider_Get_Window_Interaction_State =>
            -- UIA WindowInteractionState: Running=0, ReadyForUserInteraction=2.
            Value.all := (if Reply.Payload.Boolean_Item then 2 else 0);
         when others =>
            Value.all := (if Reply.Payload.Boolean_Item then 1 else 0);
      end case;

      return Native.Native_UInt32 (Context_View.Last_HResult_Code);
   exception
      when others =>
         if Context /= System.Null_Address
           and then Context_Conversions.To_Pointer (Context) /= null
         then
            Context_Conversions.To_Pointer (Context).Last_Status :=
              A11y.Results.Internal_Error;
            Context_Conversions.To_Pointer (Context).Last_HResult_Code :=
              16#8000_4005#;
         end if;
         return 16#8000_4005#;
   end Copy_Window_Query_Callback;

end A11y.Windows_Backend.UIA_Native_Callbacks;
