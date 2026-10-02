with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

with A11y.Resource_Limits;
with A11y.Results;

package A11y.Windows_Backend.UIA_Native_Values is

   Max_BSTR_Length       : constant Natural := 65_536;
   Max_SAFEARRAY_Length  : constant Natural := 4_096;

   type Native_Value_Kind is
     (Empty_Value,
      Not_Supported_Value,
      Boolean_Value,
      Int32_Value,
      UInt32_Value,
      BSTR_Value,
      UInt32_SAFEARRAY_Value);

   package UInt32_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive,
      Element_Type => Natural);

   type Native_Value is private;

   type Native_Value_Snapshot is record
      Kind    : Native_Value_Kind := Empty_Value;
      Status  : A11y.Results.Status_Code := A11y.Results.Success;
      Owned   : Boolean := False;
      Length  : Natural := 0;
      Count   : Natural := 0;
      Boolean_Item : Boolean := False;
      UInt32_Item  : Natural := 0;
      Int32_Item   : Integer := 0;
   end record;

   function Make_Not_Supported return Native_Value;

   function Make_Boolean (Item : Boolean) return Native_Value;

   function Make_Int32 (Item : Integer) return Native_Value;

   function Make_UInt32 (Item : Natural) return Native_Value;

   function Make_BSTR
     (Text   : String;
      Result : out A11y.Results.Result)
      return Native_Value;

   function Make_BSTR
     (Text   : String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Native_Value;

   function Make_UInt32_SAFEARRAY
     (Items  : UInt32_Vectors.Vector;
      Result : out A11y.Results.Result)
      return Native_Value;

   function Make_UInt32_SAFEARRAY
     (Items  : UInt32_Vectors.Vector;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Native_Value;

   procedure Clear
     (Value  : in out Native_Value;
      Result : out A11y.Results.Result);

   function Snapshot (Value : Native_Value) return Native_Value_Snapshot;

   function BSTR_Text (Value : Native_Value) return String;

   function SAFEARRAY_Items
     (Value : Native_Value)
      return UInt32_Vectors.Vector;

private
   type Native_Value is record
      Kind    : Native_Value_Kind := Empty_Value;
      Status  : A11y.Results.Status_Code := A11y.Results.Success;
      Owned   : Boolean := False;
      Text    : Ada.Strings.Unbounded.Unbounded_String;
      Items   : UInt32_Vectors.Vector;
      Boolean_Item : Boolean := False;
      UInt32_Item  : Natural := 0;
      Int32_Item   : Integer := 0;
   end record;

end A11y.Windows_Backend.UIA_Native_Values;
