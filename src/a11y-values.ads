with Ada.Strings.Unbounded;

with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Values is

   type Value_Kind is
     (Unknown,
      Indeterminate,
      Integer_Value,
      Decimal_Value,
      Floating_Value,
      Boolean_Value,
      Enumerated_Value);

   type Decimal is record
      Units : Long_Long_Integer := 0;
      Scale : Natural := 0;
   end record;

   type Semantic_Value (Kind : Value_Kind := Unknown) is record
      case Kind is
         when Integer_Value =>
            Integer_Item : Long_Long_Integer := 0;
         when Decimal_Value =>
            Decimal_Item : Decimal;
         when Floating_Value =>
            Floating_Item : Long_Float := 0.0;
         when Boolean_Value =>
            Boolean_Item : Boolean := False;
         when Enumerated_Value =>
            Enum_Index : Natural := 0;
         when Unknown | Indeterminate =>
            null;
      end case;
   end record;

   type Access_Mode is (Read_Only, Writable);

   type Value_Kind_Metadata is record
      Stable_Name : access constant String;
      Numeric     : Boolean := False;
      Known       : Boolean := False;
   end record;

   type Access_Mode_Metadata is record
      Stable_Name : access constant String;
      Mutable     : Boolean := False;
   end record;

   type Value_Metadata is record
      Current         : Semantic_Value := (Kind => Unknown);
      Minimum         : Semantic_Value := (Kind => Unknown);
      Maximum         : Semantic_Value := (Kind => Unknown);
      Small_Increment : Semantic_Value := (Kind => Unknown);
      Large_Increment : Semantic_Value := (Kind => Unknown);
      Mode            : Access_Mode := Read_Only;
      Units           : Ada.Strings.Unbounded.Unbounded_String;
      Presentation_Text : Ada.Strings.Unbounded.Unbounded_String;
      Precision       : Natural := 0;
   end record;

   function Integer (Item : Long_Long_Integer) return Semantic_Value
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Integer'Result.Kind = Integer_Value
        and then Integer'Result.Integer_Item = Item;
   function Exact_Decimal
     (Units : Long_Long_Integer;
      Scale : Natural)
      return Semantic_Value
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Exact_Decimal'Result.Kind = Decimal_Value
        and then Exact_Decimal'Result.Decimal_Item.Units = Units
        and then Exact_Decimal'Result.Decimal_Item.Scale = Scale;
   function Floating (Item : Long_Float) return Semantic_Value
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Floating'Result.Kind = Floating_Value
        and then Floating'Result.Floating_Item = Item;
   function Boolean (Item : Standard.Boolean) return Semantic_Value
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Boolean'Result.Kind = Boolean_Value
        and then Boolean'Result.Boolean_Item = Item;
   function Enumeration (Index : Natural) return Semantic_Value
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Enumeration'Result.Kind = Enumerated_Value
        and then Enumeration'Result.Enum_Index = Index;

   function Metadata (Kind : Value_Kind) return Value_Kind_Metadata;

   function Stable_Name (Kind : Value_Kind) return String;

   function Is_Numeric_Kind (Kind : Value_Kind) return Standard.Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Is_Numeric_Kind'Result =
          (Kind in Integer_Value | Decimal_Value | Floating_Value);
   function Is_Known_Kind (Kind : Value_Kind) return Standard.Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Is_Known_Kind'Result =
          (Kind not in Unknown | Indeterminate);

   function Metadata (Mode : Access_Mode) return Access_Mode_Metadata;

   function Stable_Name (Mode : Access_Mode) return String;

   function Is_Mutable (Mode : Access_Mode) return Standard.Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Is_Mutable'Result = (Mode = Writable);

   function Is_Numeric (Item : Semantic_Value) return Standard.Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Is_Numeric'Result = Is_Numeric_Kind (Item.Kind);
   function Is_Known (Item : Semantic_Value) return Standard.Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Is_Known'Result = Is_Known_Kind (Item.Kind);
   function Equal (Left, Right : Semantic_Value) return Standard.Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Equal'Result =
          (Left.Kind = Right.Kind
           and then
             (case Left.Kind is
                when Unknown | Indeterminate => True,
                when Integer_Value =>
                  Left.Integer_Item = Right.Integer_Item,
                when Decimal_Value =>
                  Left.Decimal_Item = Right.Decimal_Item,
                when Floating_Value =>
                  Left.Floating_Item = Right.Floating_Item,
                when Boolean_Value =>
                  Left.Boolean_Item = Right.Boolean_Item,
                when Enumerated_Value =>
                  Left.Enum_Index = Right.Enum_Index));

   function To_Long_Float
     (Item   : Semantic_Value;
      Result : out A11y.Results.Result)
      return Long_Float;

   function To_Long_Float_Lossless
     (Item   : Semantic_Value;
      Result : out A11y.Results.Result)
      return Long_Float;

   function In_Range (Metadata : Value_Metadata) return Standard.Boolean;

   function Known_Range_Bound_Is_Invalid
     (Item : Semantic_Value)
      return Standard.Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Known_Range_Bound_Is_Invalid'Result =
          (Is_Known (Item) and then not Is_Numeric (Item));

   function Known_Increment_Is_Invalid
     (Item : Semantic_Value)
      return Standard.Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Known_Increment_Is_Invalid'Result =
          (Is_Known (Item) and then not Is_Numeric (Item));

   function Known_Increment_Is_Not_Positive
     (Item : Semantic_Value)
      return Standard.Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Known_Increment_Is_Not_Positive'Result =
          (case Item.Kind is
             when Unknown | Indeterminate => False,
             when Integer_Value => Item.Integer_Item <= 0,
             when Decimal_Value => Item.Decimal_Item.Units <= 0,
             when Floating_Value => Item.Floating_Item <= 0.0,
             when Boolean_Value | Enumerated_Value => True);

   function Validate
     (Metadata : Value_Metadata;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return A11y.Results.Result;

   function Validate
     (Metadata : Value_Metadata)
      return A11y.Results.Result;

   function Validate_Numeric_Set_Request
     (Metadata        : Value_Metadata;
      Requested_Value : Semantic_Value;
      Limits          : A11y.Resource_Limits.Resource_Limit_Config)
      return A11y.Results.Result;

   function Validate_Numeric_Set_Request
     (Metadata        : Value_Metadata;
      Requested_Value : Semantic_Value)
      return A11y.Results.Result;

   type Value_Provider is limited interface;

   function Current_Metadata
     (Self : Value_Provider)
      return Value_Metadata is abstract;

   function Set_Current
     (Self            : in out Value_Provider;
      Node            : A11y.Node_Ids.Node_Id;
      Requested_Value : Semantic_Value)
      return A11y.Results.Result is abstract;

   function Current_Metadata_Safely
     (Self : Value_Provider'Class)
      return Value_Metadata;

   function Set_Current_Safely
     (Self            : in out Value_Provider'Class;
      Node            : A11y.Node_Ids.Node_Id;
      Requested_Value : Semantic_Value)
      return A11y.Results.Result;

end A11y.Values;
