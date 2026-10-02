with Ada.Strings.Unbounded;
with Ada.Containers.Vectors;

with A11y.Resource_Limits;
with A11y.Results;

package A11y.Linux.DBus_Codec is

   Max_String_Length : constant Natural := 65_536;
   Max_Array_Length  : constant Natural := 4_096;

   type Value_Kind is
     (Not_Supported_Value,
      Boolean_Value,
      Int32_Value,
      UInt32_Value,
      UInt32_Array_Value,
      String_Value,
      String_Array_Value,
      Object_Path_Array_Value,
      Object_Path_Value);

   package String_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive,
      Element_Type => Ada.Strings.Unbounded.Unbounded_String,
      "=" => Ada.Strings.Unbounded."=");

   package UInt32_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive,
      Element_Type => Natural);

   type DBus_Value (Kind : Value_Kind := Boolean_Value) is record
      case Kind is
         when Not_Supported_Value =>
            null;
         when Boolean_Value =>
            Boolean_Item : Boolean := False;
         when Int32_Value =>
            Int32_Item : Integer := 0;
         when UInt32_Value =>
            UInt32_Item : Natural := 0;
         when UInt32_Array_Value =>
            UInt32_Items : UInt32_Vectors.Vector;
         when String_Value | Object_Path_Value =>
            Text_Item : Ada.Strings.Unbounded.Unbounded_String;
         when String_Array_Value | Object_Path_Array_Value =>
            String_Items : String_Vectors.Vector;
      end case;
   end record;

   function Signature (Kind : Value_Kind) return String;
   function Is_Valid_Object_Path (Path : String) return Boolean;
   function Is_Valid_Bus_Name (Name : String) return Boolean;
   function Is_Valid_Interface_Name (Name : String) return Boolean;
   function Is_Valid_Error_Name (Name : String) return Boolean;
   function Is_Valid_Member_Name (Name : String) return Boolean;

   function Make_Not_Supported return DBus_Value;

   function Make_String
     (Text   : String;
      Result : out A11y.Results.Result)
      return DBus_Value;

   function Make_String
     (Text   : String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return DBus_Value;

   function Make_Object_Path
     (Path   : String;
      Result : out A11y.Results.Result)
      return DBus_Value;

   function Make_Object_Path
     (Path   : String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return DBus_Value;

   function Make_String_Array
     (Items  : String_Vectors.Vector;
      Result : out A11y.Results.Result)
      return DBus_Value;

   function Make_String_Array
     (Items  : String_Vectors.Vector;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return DBus_Value;

   function Make_Object_Path_Array
     (Items  : String_Vectors.Vector;
      Result : out A11y.Results.Result)
      return DBus_Value;

   function Make_Object_Path_Array
     (Items  : String_Vectors.Vector;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return DBus_Value;

   function Make_UInt32
     (Value  : Natural;
      Result : out A11y.Results.Result)
      return DBus_Value;

   function Make_Int32
     (Value  : Integer;
      Result : out A11y.Results.Result)
      return DBus_Value;

   function Make_UInt32_Array
     (Items  : UInt32_Vectors.Vector;
      Result : out A11y.Results.Result)
      return DBus_Value;

   function Make_UInt32_Array
     (Items  : UInt32_Vectors.Vector;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return DBus_Value;

   function String_Array_Items
     (Value : DBus_Value)
      return String_Vectors.Vector;

   function Object_Path_Array_Items
     (Value : DBus_Value)
      return String_Vectors.Vector;

   function UInt32_Array_Items
     (Value : DBus_Value)
      return UInt32_Vectors.Vector;

end A11y.Linux.DBus_Codec;
