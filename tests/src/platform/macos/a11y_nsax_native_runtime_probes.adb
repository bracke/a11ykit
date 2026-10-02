with System;
with System.Address_To_Access_Conversions;

with A11y.MacOS_Backend.NSAccessibility_Native_Bridge;
with Hostkit.Host;

package body A11y_NSAX_Native_Runtime_Probes is

   package Native renames A11y.MacOS_Backend.NSAccessibility_Native_Bridge;

   use type Interfaces.Unsigned_32;

   type UInt32_Buffer is array (Natural range 0 .. 127)
     of aliased Native.Native_UInt32
   with Convention => C;
   type UInt64_Buffer is array (Natural range 0 .. 127)
     of aliased Native.Native_UInt64
   with Convention => C;

   package UInt32_Buffer_Conversions is
     new System.Address_To_Access_Conversions (UInt32_Buffer);
   package UInt64_Buffer_Conversions is
     new System.Address_To_Access_Conversions (UInt64_Buffer);

   use type System.Address;
   use type Native.Native_UInt64;
   use type UInt32_Buffer_Conversions.Object_Pointer;
   use type UInt64_Buffer_Conversions.Object_Pointer;
   function Probe_Callback
     (Session  : Native.Native_UInt64;
      Node     : Native.Native_UInt64;
      Selector : Native.Native_UInt32;
      Operand  : Native.Native_UInt32;
      Context  : System.Address)
      return Native.Native_Status
   with Convention => C;

   function Probe_Callback
     (Session  : Native.Native_UInt64;
      Node     : Native.Native_UInt64;
      Selector : Native.Native_UInt32;
      Operand  : Native.Native_UInt32;
      Context  : System.Address)
      return Native.Native_Status
   is
      pragma Unreferenced (Session, Node, Selector, Operand, Context);
   begin
      return 1;
   end Probe_Callback;

   function Probe_Value_Callback
     (Session       : Native.Native_UInt64;
      Node          : Native.Native_UInt64;
      Selector      : Native.Native_UInt32;
      Operand       : Native.Native_UInt32;
      Value_Kind    : access Native.Native_UInt32;
      Items         : System.Address;
      Item_Capacity : Native.Native_UInt64;
      Item_Count    : access Native.Native_UInt64;
      UTF8_Buffer   : System.Address;
      UTF8_Capacity : Native.Native_UInt64;
      UTF8_Used     : access Native.Native_UInt64;
      Context       : System.Address)
      return Native.Native_Status
   with Convention => C;

   function Probe_Value_Callback
     (Session       : Native.Native_UInt64;
      Node          : Native.Native_UInt64;
      Selector      : Native.Native_UInt32;
      Operand       : Native.Native_UInt32;
      Value_Kind    : access Native.Native_UInt32;
      Items         : System.Address;
      Item_Capacity : Native.Native_UInt64;
      Item_Count    : access Native.Native_UInt64;
      UTF8_Buffer   : System.Address;
      UTF8_Capacity : Native.Native_UInt64;
      UTF8_Used     : access Native.Native_UInt64;
      Context       : System.Address)
      return Native.Native_Status
   is
      pragma Unreferenced
        (Session, Node, UTF8_Buffer, UTF8_Capacity, Context);
      Buffer : constant UInt32_Buffer_Conversions.Object_Pointer :=
        UInt32_Buffer_Conversions.To_Pointer (Items);
   begin
      if Value_Kind = null or else Item_Count = null or else UTF8_Used = null
      then
         return Native.Native_Status (0);
      end if;

      Value_Kind.all := 0;
      Item_Count.all := 0;
      UTF8_Used.all := 0;

      case Selector is
         when 1 =>
            if Items = System.Null_Address or else Buffer = null
              or else Item_Capacity = 0
            then
               return Native.Native_Status (0);
            end if;
            Buffer (0) := 1;
            Item_Count.all := 1;
            Value_Kind.all := 1;
            return Native.Native_Status (1);
         when 2 =>
            if Operand = 17 then
               if Items = System.Null_Address or else Buffer = null
                 or else Item_Capacity < 4
               then
                  return Native.Native_Status (0);
               end if;
               Buffer (0) := 10;
               Buffer (1) := 20;
               Buffer (2) := 300;
               Buffer (3) := 200;
               Item_Count.all := 4;
               Value_Kind.all := 7;
               return Native.Native_Status (1);
            else
               Value_Kind.all := 6;
               UTF8_Used.all := 5;
               return Native.Native_Status (1);
            end if;
         when 5 =>
            if Items = System.Null_Address or else Buffer = null
              or else Item_Capacity = 0
            then
               return Native.Native_Status (0);
            end if;
            Buffer (0) := 2;
            Item_Count.all := 1;
            Value_Kind.all := 2;
            return Native.Native_Status (1);
         when others =>
            return Native.Native_Status (0);
      end case;
   exception
      when others =>
         return Native.Native_Status (0);
   end Probe_Value_Callback;

   function Probe_Object_Callback
     (Session       : Native.Native_UInt64;
      Node          : Native.Native_UInt64;
      Selector      : Native.Native_UInt32;
      Operand       : Native.Native_UInt32;
      Point_X       : Native.Native_Int64;
      Point_Y       : Native.Native_Int64;
      Items         : System.Address;
      Item_Capacity : Native.Native_UInt64;
      Item_Count    : access Native.Native_UInt64;
      Context       : System.Address)
      return Native.Native_Status
   with Convention => C;

   function Probe_Object_Callback
     (Session       : Native.Native_UInt64;
      Node          : Native.Native_UInt64;
      Selector      : Native.Native_UInt32;
      Operand       : Native.Native_UInt32;
      Point_X       : Native.Native_Int64;
      Point_Y       : Native.Native_Int64;
      Items         : System.Address;
      Item_Capacity : Native.Native_UInt64;
      Item_Count    : access Native.Native_UInt64;
      Context       : System.Address)
      return Native.Native_Status
   is
      pragma Unreferenced (Session, Node, Point_X, Point_Y, Context);
      Buffer : constant UInt64_Buffer_Conversions.Object_Pointer :=
        UInt64_Buffer_Conversions.To_Pointer (Items);
   begin
      if Item_Count = null
        or else Items = System.Null_Address
        or else Buffer = null
        or else Item_Capacity = 0
      then
         return Native.Native_Status (0);
      end if;

      Item_Count.all := 0;
      case Selector is
         when 8 | 9 =>
            Buffer (0) := 3;
            Item_Count.all := 1;
            return Native.Native_Status (1);
         when 2 =>
            if Operand /= 1_001 then
               return Native.Native_Status (0);
            end if;
            Buffer (0) := 3;
            Item_Count.all := 1;
            return Native.Native_Status (1);
         when 10 | 11 =>
            Buffer (0) := 2;
            Item_Count.all := 1;
            return Native.Native_Status (1);
         when others =>
            return Native.Native_Status (0);
      end case;
   exception
      when others =>
         return Native.Native_Status (0);
   end Probe_Object_Callback;

   function Run_Virtual_Element_Probe return Virtual_Element_Probe_Report is
      Runtime_Available : Boolean := False;
      Mask              : Native.Native_UInt32 := 0;
      Value_Returning_Mask : Native.Native_UInt32 := 0;
      Object_Returning_Mask : Native.Native_UInt32 := 0;
   begin
      Runtime_Available := Native.Bridge_Is_MacOS /= 0;

      if Runtime_Available then
         Mask :=
           Native.Probe_Virtual_Element_Bridge
             (Probe_Callback'Access, 1, 2, System.Null_Address);
         Value_Returning_Mask :=
           Native.Probe_Value_Returning_Virtual_Element_Bridge
             (Probe_Callback'Access,
              Probe_Value_Callback'Access,
              1,
              2,
              System.Null_Address);
         Object_Returning_Mask :=
           Native.Probe_Object_Returning_Virtual_Element_Bridge
             (Probe_Callback'Access,
              Probe_Value_Callback'Access,
              Probe_Object_Callback'Access,
              1,
              2,
              System.Null_Address);
      end if;

      return
        (Native_Runtime_Available => Runtime_Available,
         Mask                     => Mask,
         Value_Returning_Mask     => Value_Returning_Mask,
         Object_Returning_Mask    => Object_Returning_Mask,
         Completed                =>
           (Mask and Native.Probe_All_Required) = Native.Probe_All_Required,
         Value_Returning_Completed =>
           (Value_Returning_Mask
            and
              (Native.Probe_Element_Created
               or Native.Probe_Identity_Matched
               or Native.Probe_Attribute_Names_Dispatched
               or Native.Probe_Attribute_Value_Dispatched
               or Native.Probe_Action_Names_Dispatched
               or Native.Probe_Released)) =
             (Native.Probe_Element_Created
              or Native.Probe_Identity_Matched
              or Native.Probe_Attribute_Names_Dispatched
             or Native.Probe_Attribute_Value_Dispatched
             or Native.Probe_Action_Names_Dispatched
              or Native.Probe_Released),
         Object_Returning_Completed =>
           (Object_Returning_Mask
            and
              (Native.Probe_Element_Created
               or Native.Probe_Identity_Matched
               or Native.Probe_Children_Dispatched
               or Native.Probe_Child_At_Index_Dispatched
               or Native.Probe_Attribute_Value_Dispatched
               or Native.Probe_Hit_Test_Dispatched
               or Native.Probe_Focused_Dispatched
               or Native.Probe_Released)) =
             (Native.Probe_Element_Created
              or Native.Probe_Identity_Matched
              or Native.Probe_Children_Dispatched
              or Native.Probe_Child_At_Index_Dispatched
              or Native.Probe_Attribute_Value_Dispatched
              or Native.Probe_Hit_Test_Dispatched
              or Native.Probe_Focused_Dispatched
              or Native.Probe_Released));
   exception
      when others =>
         return
           (Native_Runtime_Available => Runtime_Available,
            Mask                     => 0,
            Value_Returning_Mask     => 0,
            Object_Returning_Mask    => 0,
            Completed                => False,
            Value_Returning_Completed => False,
            Object_Returning_Completed => False);
   end Run_Virtual_Element_Probe;

   function Run_Public_AX_Client_Probe return Public_AX_Client_Probe_Report is
      Runtime_Available : Boolean := False;
      Process_Id        : Integer := 0;
      Process_Available : Boolean := False;
      Mask              : Native.Native_UInt32 := 0;
      Host              : System.Address := System.Null_Address;
   begin
      Runtime_Available := Native.Bridge_Is_MacOS /= 0;
      Process_Id := Hostkit.Host.Own_Process_Id;
      Process_Available := Process_Id > 0;

      if Runtime_Available and then Process_Available then
         Host :=
           Native.Install_Process_Root
             (Probe_Callback'Access,
              Probe_Value_Callback'Access,
              Probe_Object_Callback'Access,
              1,
              2,
              System.Null_Address);
         Mask :=
           Native.Probe_Public_AX_Client_For_PID
             (Native.Native_Int (Process_Id));
      end if;

      if Host /= System.Null_Address then
         Native.Release_Object (Host);
         Host := System.Null_Address;
      end if;

      return
        (Native_Runtime_Available => Runtime_Available,
         Process_Id_Available     => Process_Available,
         Mask                     => Mask,
         Completed                =>
           (Mask and Native.Public_AX_Probe_All_Required) =
             Native.Public_AX_Probe_All_Required);
   exception
      when others =>
         if Host /= System.Null_Address then
            Native.Release_Object (Host);
         end if;
         return
           (Native_Runtime_Available => Runtime_Available,
            Process_Id_Available     => Process_Available,
            Mask                     => 0,
            Completed                => False);
   end Run_Public_AX_Client_Probe;

end A11y_NSAX_Native_Runtime_Probes;
