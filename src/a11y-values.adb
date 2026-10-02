package body A11y.Values is
   Unknown_Name       : aliased constant String := "unknown";
   Indeterminate_Name : aliased constant String := "indeterminate";
   Integer_Name       : aliased constant String := "integer";
   Decimal_Name       : aliased constant String := "decimal";
   Floating_Name      : aliased constant String := "floating";
   Boolean_Name       : aliased constant String := "boolean";
   Enumerated_Name    : aliased constant String := "enumerated";

   Read_Only_Name     : aliased constant String := "read-only";
   Writable_Name      : aliased constant String := "writable";

   function Integer (Item : Long_Long_Integer) return Semantic_Value is
     (Kind => Integer_Value, Integer_Item => Item)
   with SPARK_Mode => On;

   function Exact_Decimal
     (Units : Long_Long_Integer;
      Scale : Natural)
      return Semantic_Value is
     (Kind => Decimal_Value, Decimal_Item => (Units => Units, Scale => Scale))
   with SPARK_Mode => On;

   function Floating (Item : Long_Float) return Semantic_Value is
     (Kind => Floating_Value, Floating_Item => Item)
   with SPARK_Mode => On;

   function Boolean (Item : Standard.Boolean) return Semantic_Value is
     (Kind => Boolean_Value, Boolean_Item => Item)
   with SPARK_Mode => On;

   function Enumeration (Index : Natural) return Semantic_Value is
     (Kind => Enumerated_Value, Enum_Index => Index)
   with SPARK_Mode => On;

   function Metadata (Kind : Value_Kind) return Value_Kind_Metadata is
     (case Kind is
        when Unknown =>
          (Stable_Name => Unknown_Name'Access,
           Numeric => False,
           Known => False),
        when Indeterminate =>
          (Stable_Name => Indeterminate_Name'Access,
           Numeric => False,
           Known => False),
        when Integer_Value =>
          (Stable_Name => Integer_Name'Access,
           Numeric => True,
           Known => True),
        when Decimal_Value =>
          (Stable_Name => Decimal_Name'Access,
           Numeric => True,
           Known => True),
        when Floating_Value =>
          (Stable_Name => Floating_Name'Access,
           Numeric => True,
           Known => True),
        when Boolean_Value =>
          (Stable_Name => Boolean_Name'Access,
           Numeric => False,
           Known => True),
        when Enumerated_Value =>
          (Stable_Name => Enumerated_Name'Access,
           Numeric => False,
           Known => True));

   function Stable_Name (Kind : Value_Kind) return String is
     (Metadata (Kind).Stable_Name.all);

   function Is_Numeric_Kind (Kind : Value_Kind) return Standard.Boolean is
     (Kind in Integer_Value | Decimal_Value | Floating_Value)
   with SPARK_Mode => On;

   function Is_Known_Kind (Kind : Value_Kind) return Standard.Boolean is
     (Kind not in Unknown | Indeterminate)
   with SPARK_Mode => On;

   function Metadata (Mode : Access_Mode) return Access_Mode_Metadata is
     (case Mode is
        when Read_Only =>
          (Stable_Name => Read_Only_Name'Access, Mutable => False),
        when Writable =>
          (Stable_Name => Writable_Name'Access, Mutable => True));

   function Stable_Name (Mode : Access_Mode) return String is
     (Metadata (Mode).Stable_Name.all);

   function Is_Mutable (Mode : Access_Mode) return Standard.Boolean is
     (Mode = Writable)
   with SPARK_Mode => On;

   function Is_Numeric (Item : Semantic_Value) return Standard.Boolean is
     (Is_Numeric_Kind (Item.Kind))
   with SPARK_Mode => On;

   function Is_Known (Item : Semantic_Value) return Standard.Boolean is
     (Is_Known_Kind (Item.Kind))
   with SPARK_Mode => On;

   function Decimal_To_Long_Float (Item : Decimal) return Long_Float is
      Divisor : Long_Float := 1.0;
   begin
      for Ignored in 1 .. Item.Scale loop
         pragma Unreferenced (Ignored);
         Divisor := Divisor * 10.0;
      end loop;
      return Long_Float (Item.Units) / Divisor;
   end Decimal_To_Long_Float;

   function Equal (Left, Right : Semantic_Value) return Standard.Boolean
   with SPARK_Mode => On
   is
   begin
      if Left.Kind /= Right.Kind then
         return False;
      end if;

      case Left.Kind is
         when Unknown | Indeterminate =>
            return True;
         when Integer_Value =>
            return Left.Integer_Item = Right.Integer_Item;
         when Decimal_Value =>
            return Left.Decimal_Item = Right.Decimal_Item;
         when Floating_Value =>
            return Left.Floating_Item = Right.Floating_Item;
         when Boolean_Value =>
            return Left.Boolean_Item = Right.Boolean_Item;
         when Enumerated_Value =>
            return Left.Enum_Index = Right.Enum_Index;
      end case;
   end Equal;

   function To_Long_Float
     (Item   : Semantic_Value;
      Result : out A11y.Results.Result)
      return Long_Float
   is
   begin
      case Item.Kind is
         when Integer_Value =>
            Result := A11y.Results.Ok;
            return Long_Float (Item.Integer_Item);
         when Decimal_Value =>
            Result := A11y.Results.Ok;
            return Decimal_To_Long_Float (Item.Decimal_Item);
         when Floating_Value =>
            Result := A11y.Results.Ok;
            return Item.Floating_Item;
         when Boolean_Value | Enumerated_Value =>
            Result := (Status => A11y.Results.Unsupported_Capability);
            return 0.0;
         when Unknown | Indeterminate =>
            Result := (Status => A11y.Results.Unsupported_Property);
            return 0.0;
      end case;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return 0.0;
   end To_Long_Float;

   function Integer_To_Long_Float_Lossless
     (Item   : Long_Long_Integer;
      Result : out A11y.Results.Result)
      return Long_Float
   is
      Converted : Long_Float;
   begin
      Converted := Long_Float (Item);
      if Long_Long_Integer (Converted) /= Item then
         Result := (Status => A11y.Results.Native_Failure);
         return 0.0;
      end if;

      Result := A11y.Results.Ok;
      return Converted;
   exception
      when others =>
         Result := (Status => A11y.Results.Native_Failure);
         return 0.0;
   end Integer_To_Long_Float_Lossless;

   function Decimal_To_Long_Float_Lossless
     (Item   : Decimal;
      Result : out A11y.Results.Result)
      return Long_Float
   is
      Reduced_Units : Long_Long_Integer := Item.Units;
      Remaining_Fives : Natural := Item.Scale;
      Remaining_Twos : Natural := Item.Scale;
      Ignored : Long_Float;
   begin
      while Remaining_Fives > 0
        and then Reduced_Units mod 5 = 0
      loop
         Reduced_Units := Reduced_Units / 5;
         Remaining_Fives := Remaining_Fives - 1;
      end loop;

      if Remaining_Fives > 0 then
         Result := (Status => A11y.Results.Native_Failure);
         return 0.0;
      end if;

      while Remaining_Twos > 0
        and then Reduced_Units mod 2 = 0
      loop
         Reduced_Units := Reduced_Units / 2;
         Remaining_Twos := Remaining_Twos - 1;
      end loop;

      Ignored := Integer_To_Long_Float_Lossless (Reduced_Units, Result);
      if A11y.Results.Failed (Result) then
         return 0.0;
      end if;

      Result := A11y.Results.Ok;
      return Decimal_To_Long_Float (Item);
   exception
      when others =>
         Result := (Status => A11y.Results.Native_Failure);
         return 0.0;
   end Decimal_To_Long_Float_Lossless;

   function To_Long_Float_Lossless
     (Item   : Semantic_Value;
      Result : out A11y.Results.Result)
      return Long_Float
   is
   begin
      case Item.Kind is
         when Integer_Value =>
            return Integer_To_Long_Float_Lossless (Item.Integer_Item, Result);
         when Decimal_Value =>
            return Decimal_To_Long_Float_Lossless
              (Item.Decimal_Item, Result);
         when Floating_Value =>
            Result := A11y.Results.Ok;
            return Item.Floating_Item;
         when Boolean_Value | Enumerated_Value =>
            Result := (Status => A11y.Results.Unsupported_Capability);
            return 0.0;
         when Unknown | Indeterminate =>
            Result := (Status => A11y.Results.Unsupported_Property);
            return 0.0;
      end case;
   exception
      when others =>
      Result := (Status => A11y.Results.Native_Failure);
      return 0.0;
   end To_Long_Float_Lossless;

   function Absolute_Value_Fits
     (Item  : Long_Long_Integer;
      Limit : Long_Long_Integer)
      return Standard.Boolean
   with SPARK_Mode => On
   is
   begin
      if Item = Long_Long_Integer'First then
         return False;
      elsif Item < 0 then
         return -Item <= Limit;
      else
         return Item <= Limit;
      end if;
   end Absolute_Value_Fits;

   function Power_Of_Ten
     (Scale  : Natural;
      Result : out A11y.Results.Result)
      return Long_Long_Integer
   is
      Factor : Long_Long_Integer := 1;
   begin
      for Ignored in 1 .. Scale loop
         pragma Unreferenced (Ignored);
         if Factor > Long_Long_Integer'Last / 10 then
            Result := (Status => A11y.Results.Resource_Limit);
            return 1;
         end if;
         Factor := Factor * 10;
      end loop;

      Result := A11y.Results.Ok;
      return Factor;
   end Power_Of_Ten;

   function Scale_Units
     (Units  : Long_Long_Integer;
      Scale  : Natural;
      Result : out A11y.Results.Result)
      return Long_Long_Integer
   is
      Factor : constant Long_Long_Integer := Power_Of_Ten (Scale, Result);
   begin
      if A11y.Results.Failed (Result) then
         return 0;
      elsif not Absolute_Value_Fits
        (Units, Long_Long_Integer'Last / Factor)
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return 0;
      end if;

      Result := A11y.Results.Ok;
      return Units * Factor;
   end Scale_Units;

   function Decimal_Less_Or_Equal
     (Left, Right : Decimal)
      return Standard.Boolean
   is
      Result : A11y.Results.Result;
      Left_Scaled : Long_Long_Integer;
      Right_Scaled : Long_Long_Integer;
   begin
      if Left.Scale = Right.Scale then
         return Left.Units <= Right.Units;
      elsif Left.Scale < Right.Scale then
         Left_Scaled := Scale_Units
           (Left.Units, Right.Scale - Left.Scale, Result);
         if A11y.Results.Failed (Result) then
            return False;
         end if;
         return Left_Scaled <= Right.Units;
      else
         Right_Scaled := Scale_Units
           (Right.Units, Left.Scale - Right.Scale, Result);
         if A11y.Results.Failed (Result) then
            return False;
         end if;
         return Left.Units <= Right_Scaled;
      end if;
   exception
      when others =>
         return False;
   end Decimal_Less_Or_Equal;

   function Less_Or_Equal (Left, Right : Semantic_Value) return Standard.Boolean is
   begin
      if not Is_Numeric (Left) or else not Is_Numeric (Right) then
         return False;
      elsif Left.Kind /= Right.Kind then
         return False;
      end if;

      case Left.Kind is
         when Integer_Value =>
            return Left.Integer_Item <= Right.Integer_Item;
         when Decimal_Value =>
            return Decimal_Less_Or_Equal
              (Left.Decimal_Item, Right.Decimal_Item);
         when Floating_Value =>
            return Left.Floating_Item <= Right.Floating_Item;
         when Unknown | Indeterminate | Boolean_Value | Enumerated_Value =>
            return False;
      end case;
   end Less_Or_Equal;

   function In_Range (Metadata : Value_Metadata) return Standard.Boolean is
   begin
      if not Is_Known (Metadata.Current) or else not Is_Numeric (Metadata.Current) then
         return False;
      end if;

      if Is_Known (Metadata.Minimum)
        and then not Less_Or_Equal (Metadata.Minimum, Metadata.Current)
      then
         return False;
      end if;

      if Is_Known (Metadata.Maximum)
        and then not Less_Or_Equal (Metadata.Current, Metadata.Maximum)
      then
         return False;
      end if;

      return True;
   end In_Range;

   function Known_Range_Bound_Is_Invalid
     (Item : Semantic_Value)
      return Standard.Boolean
   with SPARK_Mode => On
   is
   begin
      return Is_Known (Item) and then not Is_Numeric (Item);
   end Known_Range_Bound_Is_Invalid;

   function Known_Increment_Is_Invalid
     (Item : Semantic_Value)
      return Standard.Boolean
   with SPARK_Mode => On
   is
   begin
      return Is_Known (Item) and then not Is_Numeric (Item);
   end Known_Increment_Is_Invalid;

   function Known_Increment_Is_Not_Positive
     (Item : Semantic_Value)
      return Standard.Boolean
   with SPARK_Mode => On
   is
   begin
      case Item.Kind is
         when Unknown | Indeterminate =>
            return False;
         when Integer_Value =>
            return Item.Integer_Item <= 0;
         when Decimal_Value =>
            return Item.Decimal_Item.Units <= 0;
         when Floating_Value =>
            return Item.Floating_Item <= 0.0;
         when Boolean_Value | Enumerated_Value =>
            return True;
      end case;
   end Known_Increment_Is_Not_Positive;

   function Numeric_Kinds_Are_Coherent
     (Metadata : Value_Metadata)
      return Standard.Boolean
   is
      Reference : Value_Kind := Unknown;

      function Check (Item : Semantic_Value) return Standard.Boolean is
      begin
         if not Is_Known (Item) or else not Is_Numeric (Item) then
            return True;
         end if;

         if Reference = Unknown then
            Reference := Item.Kind;
            return True;
         end if;

         return Item.Kind = Reference;
      end Check;
   begin
      return Check (Metadata.Current)
        and then Check (Metadata.Minimum)
        and then Check (Metadata.Maximum)
        and then Check (Metadata.Small_Increment)
        and then Check (Metadata.Large_Increment);
   end Numeric_Kinds_Are_Coherent;

   function Validate
     (Metadata : Value_Metadata;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return A11y.Results.Result
   is
      Result : A11y.Results.Result;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      if A11y.Resource_Limits.Exceeded
        (Limits,
         A11y.Resource_Limits.Text_Returned,
         Ada.Strings.Unbounded.Length (Metadata.Units))
        or else A11y.Resource_Limits.Exceeded
          (Limits,
           A11y.Resource_Limits.Text_Returned,
           Ada.Strings.Unbounded.Length (Metadata.Presentation_Text))
      then
         return (Status => A11y.Results.Resource_Limit);
      end if;

      if Known_Range_Bound_Is_Invalid (Metadata.Minimum)
        or else Known_Range_Bound_Is_Invalid (Metadata.Maximum)
        or else Known_Increment_Is_Invalid (Metadata.Small_Increment)
        or else Known_Increment_Is_Invalid (Metadata.Large_Increment)
      then
         return (Status => A11y.Results.Invalid_Argument);
      end if;

      if not Numeric_Kinds_Are_Coherent (Metadata) then
         return (Status => A11y.Results.Invalid_Argument);
      end if;

      if Known_Increment_Is_Not_Positive (Metadata.Small_Increment)
        or else Known_Increment_Is_Not_Positive (Metadata.Large_Increment)
      then
         return (Status => A11y.Results.Invalid_Range);
      end if;

      if Is_Known (Metadata.Small_Increment)
        and then Is_Known (Metadata.Large_Increment)
        and then not Less_Or_Equal
          (Metadata.Small_Increment, Metadata.Large_Increment)
      then
         return (Status => A11y.Results.Invalid_Range);
      end if;

      if Is_Known (Metadata.Minimum)
        and then Is_Known (Metadata.Maximum)
        and then not Less_Or_Equal (Metadata.Minimum, Metadata.Maximum)
      then
         return (Status => A11y.Results.Invalid_Range);
      end if;

      if Is_Known (Metadata.Current)
        and then Is_Numeric (Metadata.Current)
        and then not In_Range (Metadata)
      then
         return (Status => A11y.Results.Invalid_Range);
      end if;

      return A11y.Results.Ok;
   exception
      when others =>
         return (Status => A11y.Results.Internal_Error);
   end Validate;

   function Validate
     (Metadata : Value_Metadata)
      return A11y.Results.Result is
     (Validate (Metadata, A11y.Resource_Limits.Default_Config));

   function Validate_Numeric_Set_Request
     (Metadata        : Value_Metadata;
      Requested_Value : Semantic_Value;
      Limits          : A11y.Resource_Limits.Resource_Limit_Config)
      return A11y.Results.Result
   is
      Result    : constant A11y.Results.Result := Validate (Metadata, Limits);
      Candidate : Value_Metadata := Metadata;
   begin
      if A11y.Results.Failed (Result) then
         return Result;
      elsif Metadata.Mode = Read_Only then
         return (Status => A11y.Results.Read_Only);
      elsif not Is_Numeric (Requested_Value) then
         return (Status => A11y.Results.Invalid_Argument);
      end if;

      Candidate.Current := Requested_Value;
      return Validate (Candidate, Limits);
   exception
      when others =>
         return (Status => A11y.Results.Internal_Error);
   end Validate_Numeric_Set_Request;

   function Validate_Numeric_Set_Request
     (Metadata        : Value_Metadata;
      Requested_Value : Semantic_Value)
     return A11y.Results.Result is
     (Validate_Numeric_Set_Request
        (Metadata, Requested_Value, A11y.Resource_Limits.Default_Config));

   function Current_Metadata_Safely
     (Self : Value_Provider'Class)
      return Value_Metadata
   is
      Metadata : Value_Metadata;
   begin
      Metadata := Self.Current_Metadata;
      if A11y.Results.Failed (Validate (Metadata)) then
         return (Current => (Kind => Unknown),
                 Minimum => (Kind => Unknown),
                 Maximum => (Kind => Unknown),
                 Small_Increment => (Kind => Unknown),
                 Large_Increment => (Kind => Unknown),
                 Mode => Read_Only,
                 Units => <>,
                 Presentation_Text => <>,
                 Precision => 0);
      end if;

      return Metadata;
   exception
      when others =>
         return (Current => (Kind => Unknown),
                 Minimum => (Kind => Unknown),
                 Maximum => (Kind => Unknown),
                 Small_Increment => (Kind => Unknown),
                 Large_Increment => (Kind => Unknown),
                 Mode => Read_Only,
                 Units => <>,
                 Presentation_Text => <>,
                 Precision => 0);
   end Current_Metadata_Safely;

   function Set_Current_Safely
     (Self            : in out Value_Provider'Class;
      Node            : A11y.Node_Ids.Node_Id;
      Requested_Value : Semantic_Value)
      return A11y.Results.Result
   is
      Metadata : constant Value_Metadata := Self.Current_Metadata;
      Validation : constant A11y.Results.Result :=
        Validate_Numeric_Set_Request (Metadata, Requested_Value);
   begin
      if not A11y.Node_Ids.Is_Valid (Node) then
         return (Status => A11y.Results.Node_Unavailable);
      elsif A11y.Results.Failed (Validation) then
         return Validation;
      end if;

      return Self.Set_Current (Node, Requested_Value);
   exception
      when others =>
         return (Status => A11y.Results.Internal_Error);
   end Set_Current_Safely;

end A11y.Values;
