with Ada.Strings.Fixed;

package body A11y.Linux.DBus_Auth is
   use Ada.Strings.Unbounded;

   Max_User_Id_Digits : constant Natural := 20;
   Max_Response_Length : constant Natural := 4_096;
   Server_Guid_Hex_Length : constant Natural := 32;

   function Hex_Digit (Value : Natural) return Character is
     (if Value < 10
      then Character'Val (Character'Pos ('0') + Value)
      else Character'Val (Character'Pos ('A') + Value - 10));

   function Is_Hex (Ch : Character) return Boolean is
     (Ch in '0' .. '9' or else Ch in 'A' .. 'F' or else Ch in 'a' .. 'f');

   function Is_Hex_Text
     (Text        : String;
      Allow_Empty : Boolean)
      return Boolean
   is
   begin
      if Text'Length = 0 then
         return Allow_Empty;
      elsif Text'Length mod 2 /= 0 then
         return False;
      end if;

      for Ch of Text loop
         if not Is_Hex (Ch) then
            return False;
         end if;
      end loop;

      return True;
   end Is_Hex_Text;

   function Is_Token_Character (Ch : Character) return Boolean is
     (Character'Pos (Ch) >= 33 and then Character'Pos (Ch) <= 126);

   function Encode_External_User_Id
     (User_Id : External_User_Id;
      Result  : out A11y.Results.Result)
      return String
   is
      Decimal : constant String := Ada.Strings.Fixed.Trim
        (External_User_Id'Image (User_Id), Ada.Strings.Left);
      Encoded : String (1 .. Decimal'Length * 2);
      Out_Index : Positive := Encoded'First;
   begin
      if Decimal'Length = 0 or else Decimal'Length > Max_User_Id_Digits then
         Result := (Status => A11y.Results.Resource_Limit);
         return "";
      end if;

      for Ch of Decimal loop
         Encoded (Out_Index) := Hex_Digit (Character'Pos (Ch) / 16);
         Encoded (Out_Index + 1) := Hex_Digit (Character'Pos (Ch) mod 16);
         Out_Index := Out_Index + 2;
      end loop;

      Result := A11y.Results.Ok;
      return Encoded;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return "";
   end Encode_External_User_Id;

   function Auth_External_Command
     (User_Id : External_User_Id;
      Result  : out A11y.Results.Result)
      return Unbounded_String
   is
      Encoded : constant String := Encode_External_User_Id (User_Id, Result);
   begin
      if A11y.Results.Failed (Result) then
         return Null_Unbounded_String;
      end if;

      return To_Unbounded_String
        (Character'Val (0) & "AUTH EXTERNAL " & Encoded & Character'Val (13)
         & Character'Val (10));
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Null_Unbounded_String;
   end Auth_External_Command;

   function Begin_Command return Unbounded_String is
     (To_Unbounded_String ("BEGIN" & Character'Val (13) & Character'Val (10)));

   function Decode_Response
     (Line   : String;
      Result : out A11y.Results.Result)
      return Auth_Response
   is
      Last : Natural := Line'Last;

      function Decode_Text (Text : String) return Auth_Response
      is
         Space : Natural;

         function Tail return String is
           (if Space = 0 or else Space = Text'Last
            then ""
            else Text (Space + 1 .. Text'Last));
      begin
         if Text'Length = 0 then
            Result := (Status => A11y.Results.Invalid_Argument);
            return (Kind => Auth_Unknown, Challenge => Null_Unbounded_String);
         end if;

         for Ch of Text loop
            if not Is_Token_Character (Ch) and then Ch /= ' ' then
               Result := (Status => A11y.Results.Invalid_Argument);
               return (Kind => Auth_Unknown, Challenge => Null_Unbounded_String);
            end if;
         end loop;

         Space := Ada.Strings.Fixed.Index (Text, " ");
         if Space = 0 then
            if Text = "OK" then
               Result := (Status => A11y.Results.Invalid_Argument);
               return (Kind => Auth_Unknown, Challenge => Null_Unbounded_String);
            elsif Text = "REJECTED" then
               Result := A11y.Results.Ok;
               return (Kind => Auth_Rejected, Challenge => Null_Unbounded_String);
            elsif Text = "ERROR" then
               Result := A11y.Results.Ok;
               return (Kind => Auth_Error, Challenge => Null_Unbounded_String);
            elsif Text = "DATA" then
               Result := A11y.Results.Ok;
               return (Kind => Auth_Data, Challenge => Null_Unbounded_String);
            else
               Result := (Status => A11y.Results.Unsupported_Capability);
               return (Kind => Auth_Unknown, Challenge => Null_Unbounded_String);
            end if;
         end if;

         if Text (Text'First .. Space - 1) = "OK" then
            if Tail'Length /= Server_Guid_Hex_Length
              or else not Is_Hex_Text (Tail, Allow_Empty => False)
            then
               Result := (Status => A11y.Results.Invalid_Argument);
               return (Kind => Auth_Unknown, Challenge => Null_Unbounded_String);
            end if;
            Result := A11y.Results.Ok;
            return (Kind => Auth_Ok, Challenge => To_Unbounded_String (Tail));
         elsif Text (Text'First .. Space - 1) = "REJECTED" then
            Result := A11y.Results.Ok;
            return (Kind => Auth_Rejected, Challenge => To_Unbounded_String (Tail));
         elsif Text (Text'First .. Space - 1) = "ERROR" then
            Result := A11y.Results.Ok;
            return (Kind => Auth_Error, Challenge => To_Unbounded_String (Tail));
         elsif Text (Text'First .. Space - 1) = "DATA" then
            if not Is_Hex_Text (Tail, Allow_Empty => True) then
               Result := (Status => A11y.Results.Invalid_Argument);
               return (Kind => Auth_Unknown, Challenge => Null_Unbounded_String);
            end if;
            Result := A11y.Results.Ok;
            return (Kind => Auth_Data, Challenge => To_Unbounded_String (Tail));
         else
            Result := (Status => A11y.Results.Unsupported_Capability);
            return (Kind => Auth_Unknown, Challenge => Null_Unbounded_String);
         end if;
      end Decode_Text;
   begin
      if Line'Length = 0 or else Line'Length > Max_Response_Length then
         Result := (Status => A11y.Results.Invalid_Argument);
         return (Kind => Auth_Unknown, Challenge => Null_Unbounded_String);
      end if;

      if Line'Length < 2
        or else Line (Line'Last - 1) /= Character'Val (13)
        or else Line (Line'Last) /= Character'Val (10)
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return (Kind => Auth_Unknown, Challenge => Null_Unbounded_String);
      end if;
      Last := Line'Last - 2;

      if Last < Line'First then
         Result := (Status => A11y.Results.Invalid_Argument);
         return (Kind => Auth_Unknown, Challenge => Null_Unbounded_String);
      else
         return Decode_Text (Line (Line'First .. Last));
      end if;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return (Kind => Auth_Unknown, Challenge => Null_Unbounded_String);
   end Decode_Response;

end A11y.Linux.DBus_Auth;
