with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

with A11y.Resource_Limits;
with A11y.Results;

package A11y.MacOS_Backend.NSAccessibility_Native_Values is

   Max_NSString_Length : constant Natural := 65_536;
   Max_NSArray_Length  : constant Natural := 4_096;

   type Native_Value_Kind is
     (Nil_Value,
      Not_Applicable_Value,
      Boolean_Value,
      UInt32_Value,
      NSString_Value,
      NSArray_UInt32_Value);

   package UInt32_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive,
      Element_Type => Natural);

   type Native_Value is private;

   type Native_Value_Snapshot is record
      Kind    : Native_Value_Kind := Nil_Value;
      Status  : A11y.Results.Status_Code := A11y.Results.Success;
      Owned   : Boolean := False;
      Length  : Natural := 0;
      Count   : Natural := 0;
      Boolean_Item : Boolean := False;
      UInt32_Item  : Natural := 0;
   end record;

   function Make_Nil return Native_Value;

   function Make_Not_Applicable return Native_Value;

   function Make_Boolean (Item : Boolean) return Native_Value;

   function Make_UInt32 (Item : Natural) return Native_Value;

   function Make_NSString
     (Text   : String;
      Result : out A11y.Results.Result)
      return Native_Value;

   function Make_NSString
     (Text   : String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Native_Value;

   function Make_NSArray_UInt32
     (Items  : UInt32_Vectors.Vector;
      Result : out A11y.Results.Result)
      return Native_Value;

   function Make_NSArray_UInt32
     (Items  : UInt32_Vectors.Vector;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Native_Value;

   procedure Clear
     (Value  : in out Native_Value;
      Result : out A11y.Results.Result);

   function Snapshot (Value : Native_Value) return Native_Value_Snapshot;

   function NSString_Text (Value : Native_Value) return String;

   function NSArray_Items
     (Value : Native_Value)
      return UInt32_Vectors.Vector;

private
   type Native_Value is record
      Kind    : Native_Value_Kind := Nil_Value;
      Status  : A11y.Results.Status_Code := A11y.Results.Success;
      Owned   : Boolean := False;
      Text    : Ada.Strings.Unbounded.Unbounded_String;
      Items   : UInt32_Vectors.Vector;
      Boolean_Item : Boolean := False;
      UInt32_Item  : Natural := 0;
   end record;

end A11y.MacOS_Backend.NSAccessibility_Native_Values;
