package body A11y.Windows_Backend.UIA_Native_Values is
   use Ada.Strings.Unbounded;

   function Empty_With_Status
     (Status : A11y.Results.Status_Code)
      return Native_Value is
     (Kind         => Empty_Value,
      Status       => Status,
      Owned        => False,
      Text         => Null_Unbounded_String,
      Items        => UInt32_Vectors.Empty_Vector,
      Boolean_Item => False,
      UInt32_Item  => 0,
      Int32_Item   => 0);

   function Max_UInt32_Value return Long_Long_Integer is
     (4_294_967_295);
   pragma No_Inline (Max_UInt32_Value);

   function Make_Not_Supported return Native_Value is
     (Kind         => Not_Supported_Value,
      Status       => A11y.Results.Unsupported_Property,
      Owned        => False,
      Text         => Null_Unbounded_String,
      Items        => UInt32_Vectors.Empty_Vector,
      Boolean_Item => False,
      UInt32_Item  => 0,
      Int32_Item   => 0);

   function Make_Boolean (Item : Boolean) return Native_Value is
     (Kind         => Boolean_Value,
      Status       => A11y.Results.Success,
      Owned        => False,
      Text         => Null_Unbounded_String,
      Items        => UInt32_Vectors.Empty_Vector,
      Boolean_Item => Item,
      UInt32_Item  => 0,
      Int32_Item   => 0);

   function Make_Int32 (Item : Integer) return Native_Value is
     (Kind         => Int32_Value,
      Status       => A11y.Results.Success,
      Owned        => False,
      Text         => Null_Unbounded_String,
      Items        => UInt32_Vectors.Empty_Vector,
      Boolean_Item => False,
      UInt32_Item  => 0,
      Int32_Item   => Item);

   function Make_UInt32 (Item : Natural) return Native_Value is
   begin
      if Long_Long_Integer (Item) > Max_UInt32_Value then
         return Empty_With_Status (A11y.Results.Resource_Limit);
      end if;

      return
        (Kind         => UInt32_Value,
         Status       => A11y.Results.Success,
         Owned        => False,
         Text         => Null_Unbounded_String,
         Items        => UInt32_Vectors.Empty_Vector,
         Boolean_Item => False,
         UInt32_Item  => Item,
         Int32_Item   => 0);
   end Make_UInt32;

   function Configured_Limit
     (Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Kind    : A11y.Resource_Limits.Limit_Kind;
      Maximum : Natural;
      Result  : out A11y.Results.Result)
      return Natural
   is
      Limit : Natural;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return 0;
      end if;

      Limit := Natural (A11y.Resource_Limits.Value (Limits, Kind));
      if Limit > Maximum then
         Result := (Status => A11y.Results.Invalid_Argument);
         return 0;
      end if;

      Result := A11y.Results.Ok;
      return Limit;
   end Configured_Limit;

   function Make_BSTR
     (Text   : String;
      Result : out A11y.Results.Result)
      return Native_Value
   is
   begin
      return Make_BSTR
        (Text, A11y.Resource_Limits.Default_Config, Result);
   end Make_BSTR;

   function Make_BSTR
     (Text   : String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Native_Value
   is
      Limit : constant Natural :=
        Configured_Limit
          (Limits, A11y.Resource_Limits.Native_String_Size,
           Max_BSTR_Length, Result);
   begin
      if A11y.Results.Failed (Result) then
         return Empty_With_Status (Result.Status);
      elsif Text'Length > Limit then
         Result := (Status => A11y.Results.Resource_Limit);
         return Empty_With_Status (Result.Status);
      end if;

      Result := A11y.Results.Ok;
      return
        (Kind         => BSTR_Value,
         Status       => A11y.Results.Success,
         Owned        => True,
         Text         => To_Unbounded_String (Text),
         Items        => UInt32_Vectors.Empty_Vector,
         Boolean_Item => False,
         UInt32_Item  => 0,
         Int32_Item   => 0);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Empty_With_Status (Result.Status);
   end Make_BSTR;

   function Make_UInt32_SAFEARRAY
     (Items  : UInt32_Vectors.Vector;
      Result : out A11y.Results.Result)
      return Native_Value
   is
   begin
      return Make_UInt32_SAFEARRAY
        (Items, A11y.Resource_Limits.Default_Config, Result);
   end Make_UInt32_SAFEARRAY;

   function Make_UInt32_SAFEARRAY
     (Items  : UInt32_Vectors.Vector;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Native_Value
   is
      Limit : constant Natural :=
        Configured_Limit
          (Limits, A11y.Resource_Limits.Native_Array_Size,
           Max_SAFEARRAY_Length, Result);
   begin
      if A11y.Results.Failed (Result) then
         return Empty_With_Status (Result.Status);
      elsif Natural (Items.Length) > Limit then
         Result := (Status => A11y.Results.Resource_Limit);
         return Empty_With_Status (Result.Status);
      end if;

      for Item of Items loop
         if Long_Long_Integer (Item) > Max_UInt32_Value then
            Result := (Status => A11y.Results.Resource_Limit);
            return Empty_With_Status (Result.Status);
         end if;
      end loop;

      Result := A11y.Results.Ok;
      return
        (Kind         => UInt32_SAFEARRAY_Value,
         Status       => A11y.Results.Success,
         Owned        => True,
         Text         => Null_Unbounded_String,
         Items        => Items,
         Boolean_Item => False,
         UInt32_Item  => 0,
         Int32_Item   => 0);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Empty_With_Status (Result.Status);
   end Make_UInt32_SAFEARRAY;

   procedure Clear
     (Value  : in out Native_Value;
      Result : out A11y.Results.Result)
   is
   begin
      Value.Kind := Empty_Value;
      Value.Status := A11y.Results.Success;
      Value.Owned := False;
      Value.Text := Null_Unbounded_String;
      Value.Items.Clear;
      Value.Boolean_Item := False;
      Value.UInt32_Item := 0;
      Value.Int32_Item := 0;
      Result := A11y.Results.Ok;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Clear;

   function Snapshot (Value : Native_Value) return Native_Value_Snapshot is
     (Kind         => Value.Kind,
      Status       => Value.Status,
      Owned        => Value.Owned,
      Length       => Length (Value.Text),
      Count        => Natural (Value.Items.Length),
      Boolean_Item => Value.Boolean_Item,
      UInt32_Item  => Value.UInt32_Item,
      Int32_Item   => Value.Int32_Item);

   function BSTR_Text (Value : Native_Value) return String is
     (if Value.Kind = BSTR_Value then To_String (Value.Text) else "");

   function SAFEARRAY_Items
     (Value : Native_Value)
      return UInt32_Vectors.Vector is
     (if Value.Kind = UInt32_SAFEARRAY_Value
      then Value.Items
      else UInt32_Vectors.Empty_Vector);

end A11y.Windows_Backend.UIA_Native_Values;
