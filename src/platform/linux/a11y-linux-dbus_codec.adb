package body A11y.Linux.DBus_Codec is
   use Ada.Strings.Unbounded;

   function Max_UInt32_Value return Long_Long_Integer is
     (4_294_967_295);
   pragma No_Inline (Max_UInt32_Value);

   function Signature (Kind : Value_Kind) return String is
     (case Kind is
        when Not_Supported_Value => "",
        when Boolean_Value => "b",
        when Int32_Value => "i",
        when UInt32_Value => "u",
        when UInt32_Array_Value => "au",
        when String_Value => "s",
        when String_Array_Value => "as",
        when Object_Path_Array_Value => "ao",
        when Object_Path_Value => "o");

   function Make_Not_Supported return DBus_Value is
     (Kind => Not_Supported_Value);

   function Is_Valid_Path_Character (Ch : Character) return Boolean is
     (Ch in 'A' .. 'Z'
      or else Ch in 'a' .. 'z'
      or else Ch in '0' .. '9'
      or else Ch = '_');

   function Is_Valid_Bus_Name_Character (Ch : Character) return Boolean is
     (Ch in 'A' .. 'Z'
      or else Ch in 'a' .. 'z'
      or else Ch in '0' .. '9'
      or else Ch in '_' | '-');

   function Is_Valid_Interface_Character (Ch : Character) return Boolean is
     (Ch in 'A' .. 'Z'
      or else Ch in 'a' .. 'z'
      or else Ch in '0' .. '9'
      or else Ch = '_');

   function Is_Valid_Member_Character (Ch : Character) return Boolean is
     (Ch in 'A' .. 'Z'
      or else Ch in 'a' .. 'z'
      or else Ch in '0' .. '9'
      or else Ch = '_');

   function Is_Valid_Bus_Name (Name : String) return Boolean is
      First_Element_Character : Boolean := True;
      Saw_Dot : Boolean := False;
      Unique : Boolean := False;
   begin
      if Name'Length = 0 or else Name'Length > 255 then
         return False;
      end if;

      Unique := Name (Name'First) = ':';
      if Unique and then Name'Length = 1 then
         return False;
      end if;

      for Index in (if Unique then Name'First + 1 else Name'First)
        .. Name'Last
      loop
         if Name (Index) = '.' then
            if First_Element_Character then
               return False;
            end if;

            Saw_Dot := True;
            First_Element_Character := True;
         else
            if not Is_Valid_Bus_Name_Character (Name (Index)) then
               return False;
            elsif First_Element_Character
              and then not Unique
              and then Name (Index) in '0' .. '9'
            then
               return False;
            end if;

            First_Element_Character := False;
         end if;
      end loop;

      return Saw_Dot and then not First_Element_Character;
   end Is_Valid_Bus_Name;

   function Is_Valid_Interface_Name (Name : String) return Boolean is
      First_Element_Character : Boolean := True;
      Saw_Dot : Boolean := False;
   begin
      if Name'Length = 0 or else Name'Length > 255 then
         return False;
      end if;

      for Index in Name'Range loop
         if Name (Index) = '.' then
            if First_Element_Character then
               return False;
            end if;

            Saw_Dot := True;
            First_Element_Character := True;
         else
            if not Is_Valid_Interface_Character (Name (Index)) then
               return False;
            elsif First_Element_Character
              and then Name (Index) in '0' .. '9'
            then
               return False;
            end if;

            First_Element_Character := False;
         end if;
      end loop;

      return Saw_Dot and then not First_Element_Character;
   end Is_Valid_Interface_Name;

   function Is_Valid_Error_Name (Name : String) return Boolean is
     (Is_Valid_Interface_Name (Name));

   function Is_Valid_Member_Name (Name : String) return Boolean is
   begin
      if Name'Length = 0
        or else Name'Length > 255
        or else Name (Name'First) in '0' .. '9'
      then
         return False;
      end if;

      for Ch of Name loop
         if not Is_Valid_Member_Character (Ch) then
            return False;
         end if;
      end loop;

      return True;
   end Is_Valid_Member_Name;

   function Is_Valid_Object_Path (Path : String) return Boolean is
      Last_Was_Slash : Boolean := False;
   begin
      if Path'Length = 0 or else Path (Path'First) /= '/' then
         return False;
      end if;

      if Path'Length = 1 then
         return True;
      end if;

      for Index in Path'Range loop
         if Path (Index) = '/' then
            if Last_Was_Slash then
               return False;
            end if;
            Last_Was_Slash := True;
         else
            if not Is_Valid_Path_Character (Path (Index)) then
               return False;
            end if;
            Last_Was_Slash := False;
         end if;
      end loop;

      return not Last_Was_Slash;
   end Is_Valid_Object_Path;

   function Configured_String_Limit
     (Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Natural
   is
      Limit : Natural;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return 0;
      end if;

      Limit := Natural
        (A11y.Resource_Limits.Value
           (Limits, A11y.Resource_Limits.Native_String_Size));
      if Limit > Max_String_Length then
         Result := (Status => A11y.Results.Invalid_Argument);
         return 0;
      end if;

      Result := A11y.Results.Ok;
      return Limit;
   end Configured_String_Limit;

   function Configured_Array_Limit
     (Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Natural
   is
      Limit : Natural;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return 0;
      end if;

      Limit := Natural
        (A11y.Resource_Limits.Value
           (Limits, A11y.Resource_Limits.Native_Array_Size));
      if Limit > Max_Array_Length then
         Result := (Status => A11y.Results.Invalid_Argument);
         return 0;
      end if;

      Result := A11y.Results.Ok;
      return Limit;
   end Configured_Array_Limit;

   function Make_String
     (Text   : String;
      Result : out A11y.Results.Result)
      return DBus_Value
   is
   begin
      return Make_String
        (Text, A11y.Resource_Limits.Default_Config, Result);
   end Make_String;

   function Make_String
     (Text   : String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return DBus_Value
   is
      Limit : constant Natural := Configured_String_Limit (Limits, Result);
   begin
      if A11y.Results.Failed (Result) then
         return (Kind => String_Value, Text_Item => Null_Unbounded_String);
      elsif Text'Length > Limit then
         Result := (Status => A11y.Results.Resource_Limit);
         return (Kind => String_Value, Text_Item => Null_Unbounded_String);
      end if;

      Result := A11y.Results.Ok;
      return (Kind => String_Value, Text_Item => To_Unbounded_String (Text));
   end Make_String;

   function Make_Object_Path
     (Path   : String;
      Result : out A11y.Results.Result)
      return DBus_Value
   is
   begin
      return Make_Object_Path
        (Path, A11y.Resource_Limits.Default_Config, Result);
   end Make_Object_Path;

   function Make_Object_Path
     (Path   : String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return DBus_Value
   is
      Limit : constant Natural := Configured_String_Limit (Limits, Result);
   begin
      if A11y.Results.Failed (Result) then
         return (Kind => Object_Path_Value, Text_Item => Null_Unbounded_String);
      elsif Path'Length > Limit then
         Result := (Status => A11y.Results.Resource_Limit);
         return (Kind => Object_Path_Value, Text_Item => Null_Unbounded_String);
      elsif not Is_Valid_Object_Path (Path) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return (Kind => Object_Path_Value, Text_Item => Null_Unbounded_String);
      end if;

      Result := A11y.Results.Ok;
      return (Kind => Object_Path_Value, Text_Item => To_Unbounded_String (Path));
   end Make_Object_Path;

   function Make_String_Array
     (Items  : String_Vectors.Vector;
      Result : out A11y.Results.Result)
      return DBus_Value
   is
   begin
      return Make_String_Array
        (Items, A11y.Resource_Limits.Default_Config, Result);
   end Make_String_Array;

   function Make_String_Array
     (Items  : String_Vectors.Vector;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return DBus_Value
   is
      Array_Limit : constant Natural := Configured_Array_Limit (Limits, Result);
      String_Limit : Natural;
   begin
      if A11y.Results.Failed (Result) then
         return
           (Kind => String_Array_Value,
            String_Items => String_Vectors.Empty_Vector);
      elsif Natural (Items.Length) > Array_Limit then
         Result := (Status => A11y.Results.Resource_Limit);
         return
           (Kind => String_Array_Value,
            String_Items => String_Vectors.Empty_Vector);
      end if;

      String_Limit := Configured_String_Limit (Limits, Result);
      if A11y.Results.Failed (Result) then
         return
           (Kind => String_Array_Value,
            String_Items => String_Vectors.Empty_Vector);
      end if;

      for Item of Items loop
         if Length (Item) > String_Limit then
            Result := (Status => A11y.Results.Resource_Limit);
            return
              (Kind => String_Array_Value,
               String_Items => String_Vectors.Empty_Vector);
         end if;
      end loop;

      Result := A11y.Results.Ok;
      return (Kind => String_Array_Value, String_Items => Items);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Kind => String_Array_Value,
            String_Items => String_Vectors.Empty_Vector);
   end Make_String_Array;

   function Make_Object_Path_Array
     (Items  : String_Vectors.Vector;
      Result : out A11y.Results.Result)
      return DBus_Value
   is
   begin
      return Make_Object_Path_Array
        (Items, A11y.Resource_Limits.Default_Config, Result);
   end Make_Object_Path_Array;

   function Make_Object_Path_Array
     (Items  : String_Vectors.Vector;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return DBus_Value
   is
      Array_Limit : constant Natural := Configured_Array_Limit (Limits, Result);
      String_Limit : Natural;
   begin
      if A11y.Results.Failed (Result) then
         return
           (Kind => Object_Path_Array_Value,
            String_Items => String_Vectors.Empty_Vector);
      elsif Natural (Items.Length) > Array_Limit then
         Result := (Status => A11y.Results.Resource_Limit);
         return
           (Kind => Object_Path_Array_Value,
            String_Items => String_Vectors.Empty_Vector);
      end if;

      String_Limit := Configured_String_Limit (Limits, Result);
      if A11y.Results.Failed (Result) then
         return
           (Kind => Object_Path_Array_Value,
            String_Items => String_Vectors.Empty_Vector);
      end if;

      for Item of Items loop
         declare
            Path : constant String := To_String (Item);
         begin
            if Path'Length > String_Limit then
               Result := (Status => A11y.Results.Resource_Limit);
               return
                 (Kind => Object_Path_Array_Value,
                  String_Items => String_Vectors.Empty_Vector);
            elsif not Is_Valid_Object_Path (Path) then
               Result := (Status => A11y.Results.Invalid_Argument);
               return
                 (Kind => Object_Path_Array_Value,
                  String_Items => String_Vectors.Empty_Vector);
            end if;
         end;
      end loop;

      Result := A11y.Results.Ok;
      return (Kind => Object_Path_Array_Value, String_Items => Items);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Kind => Object_Path_Array_Value,
            String_Items => String_Vectors.Empty_Vector);
   end Make_Object_Path_Array;

   function Make_UInt32
     (Value  : Natural;
      Result : out A11y.Results.Result)
      return DBus_Value
   is
   begin
      if Long_Long_Integer (Value) > Max_UInt32_Value then
         Result := (Status => A11y.Results.Resource_Limit);
         return (Kind => UInt32_Value, UInt32_Item => 0);
      end if;

      Result := A11y.Results.Ok;
      return (Kind => UInt32_Value, UInt32_Item => Value);
   end Make_UInt32;

   function Make_Int32
     (Value  : Integer;
      Result : out A11y.Results.Result)
      return DBus_Value
   is
   begin
      Result := A11y.Results.Ok;
      return (Kind => Int32_Value, Int32_Item => Value);
   end Make_Int32;

   function Make_UInt32_Array
     (Items  : UInt32_Vectors.Vector;
      Result : out A11y.Results.Result)
      return DBus_Value
   is
   begin
      return Make_UInt32_Array
        (Items, A11y.Resource_Limits.Default_Config, Result);
   end Make_UInt32_Array;

   function Make_UInt32_Array
     (Items  : UInt32_Vectors.Vector;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return DBus_Value
   is
      Array_Limit : constant Natural := Configured_Array_Limit (Limits, Result);
   begin
      if A11y.Results.Failed (Result) then
         return
           (Kind => UInt32_Array_Value,
            UInt32_Items => UInt32_Vectors.Empty_Vector);
      elsif Natural (Items.Length) > Array_Limit then
         Result := (Status => A11y.Results.Resource_Limit);
         return
           (Kind => UInt32_Array_Value,
            UInt32_Items => UInt32_Vectors.Empty_Vector);
      end if;

      for Item of Items loop
         if Long_Long_Integer (Item) > Max_UInt32_Value then
            Result := (Status => A11y.Results.Resource_Limit);
            return
              (Kind => UInt32_Array_Value,
               UInt32_Items => UInt32_Vectors.Empty_Vector);
         end if;
      end loop;

      Result := A11y.Results.Ok;
      return (Kind => UInt32_Array_Value, UInt32_Items => Items);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Kind => UInt32_Array_Value,
            UInt32_Items => UInt32_Vectors.Empty_Vector);
   end Make_UInt32_Array;

   function String_Array_Items
     (Value : DBus_Value)
      return String_Vectors.Vector is
     (if Value.Kind = String_Array_Value
      then Value.String_Items
      else String_Vectors.Empty_Vector);

   function Object_Path_Array_Items
     (Value : DBus_Value)
      return String_Vectors.Vector is
     (if Value.Kind = Object_Path_Array_Value
      then Value.String_Items
      else String_Vectors.Empty_Vector);

   function UInt32_Array_Items
     (Value : DBus_Value)
      return UInt32_Vectors.Vector is
     (if Value.Kind = UInt32_Array_Value
      then Value.UInt32_Items
      else UInt32_Vectors.Empty_Vector);

end A11y.Linux.DBus_Codec;
