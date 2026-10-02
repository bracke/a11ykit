with Ada.Characters.Handling;
with A11y.Backends.Native_Backends;

package body A11y.Backends.Selection is

   function Normalize (Text : String) return String is
      use Ada.Characters.Handling;
      Result : String (Text'Range);
   begin
      for Index in Text'Range loop
         Result (Index) := To_Lower (Text (Index));
      end loop;
      return Result;
   end Normalize;

   function Parse (Override : String) return Selection_Mode is
      Lower : constant String := Normalize (Override);
   begin
      if Override'Length = 0 or else Lower = "default" then
         return Use_Default;
      elsif Lower = "native" then
         return Use_Native;
      elsif Lower = "null" then
         return Use_Null;
      elsif Lower = "disabled" or else Lower = "off" then
         return Use_Disabled;
      else
         return Invalid;
      end if;
   end Parse;

   function Is_Valid_Mode
     (Mode : Selection_Mode)
      return Boolean is
     (Mode /= Invalid)
   with SPARK_Mode => On;

   function Is_Explicit_Mode
     (Mode : Selection_Mode)
      return Boolean is
     (Mode in Use_Native | Use_Null | Use_Disabled)
   with SPARK_Mode => On;

   function Requires_Native_Transport
     (Mode : Selection_Mode)
      return Boolean is
     (Mode = Use_Native)
   with SPARK_Mode => On;

   function Expected_Selected_Backend
     (Mode                    : Selection_Mode;
      Native_Target_Supported : Boolean;
      Native_Available        : Boolean)
      return Backend_Kind is
     (case Mode is
        when Use_Disabled =>
          Disabled,
        when Use_Null | Invalid =>
          Null_Backend,
        when Use_Native =>
          (if Native_Target_Supported then Native else Null_Backend),
        when Use_Default =>
          (if Native_Target_Supported and then Native_Available then
             Native
           else
             Null_Backend))
   with SPARK_Mode => On;

   function Expected_Status
     (Mode                    : Selection_Mode;
      Native_Target_Supported : Boolean;
      Native_Available        : Boolean)
      return A11y.Results.Status_Code is
     (if Mode = Invalid then
        A11y.Results.Invalid_Argument
      elsif Mode in Use_Null | Use_Disabled then
        A11y.Results.Success
      elsif Native_Target_Supported and then Native_Available then
        A11y.Results.Success
      else
        A11y.Results.Backend_Unavailable)
   with SPARK_Mode => On;

   function Expected_Fallback
     (Mode                    : Selection_Mode;
      Native_Target_Supported : Boolean;
      Native_Available        : Boolean)
      return Boolean is
     (Mode = Invalid
      or else (Mode = Use_Native and then not Native_Target_Supported)
      or else (Mode = Use_Default
               and then not
                 (Native_Target_Supported and then Native_Available)))
   with SPARK_Mode => On;

   function Native_Target_Supported return Boolean is
     (A11y.Backends.Native_Backends.Target_For_Current_Platform.Supported);

   function Native_Available return Boolean is
   begin
      --  Native backends have mapping/method scaffolds, but no registered OS
      --  provider implementation yet. Do not select them as available.
      return False;
   end Native_Available;

   function Resolve (Override : String) return Selection_Result is
      Requested : constant Selection_Mode := Parse (Override);
      Target_Supported : constant Boolean := Native_Target_Supported;
      Available        : constant Boolean := Native_Available;
   begin
      return
        (Requested => Requested,
         Selected  => Expected_Selected_Backend
           (Requested, Target_Supported, Available),
         Status    => Expected_Status
           (Requested, Target_Supported, Available),
         Fallback  => Expected_Fallback
           (Requested, Target_Supported, Available));
   end Resolve;

end A11y.Backends.Selection;
