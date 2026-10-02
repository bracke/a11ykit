with A11y.Text.Classification;

package body A11y.Text is
   use Ada.Strings.Wide_Wide_Unbounded;

   Plain_Text_Name     : aliased constant String := "plain-text";
   Protected_Text_Name : aliased constant String := "protected-text";
   Insert_Text_Name    : aliased constant String := "insert-text";
   Delete_Text_Name    : aliased constant String := "delete-text";
   Replace_Text_Name   : aliased constant String := "replace-text";
   Set_Text_Name       : aliased constant String := "set-text";

   function Metadata
     (Policy : Protected_Text_Policy)
      return Protected_Text_Metadata is
     (case Policy is
        when Plain_Text =>
          (Stable_Name => Plain_Text_Name'Access,
           Exposes_Text => True),
        when Protected_Text =>
          (Stable_Name => Protected_Text_Name'Access,
           Exposes_Text => False));

   function Stable_Name (Policy : Protected_Text_Policy) return String is
     (Metadata (Policy).Stable_Name.all);

   function Metadata (Kind : Text_Edit_Kind) return Text_Edit_Metadata is
     (case Kind is
        when Insert_Text =>
          (Stable_Name    => Insert_Text_Name'Access,
           Requires_Range => True,
           Requires_Text  => True),
        when Delete_Text =>
          (Stable_Name    => Delete_Text_Name'Access,
           Requires_Range => True,
           Requires_Text  => False),
        when Replace_Text =>
          (Stable_Name    => Replace_Text_Name'Access,
           Requires_Range => True,
           Requires_Text  => True),
        when Set_Text =>
          (Stable_Name    => Set_Text_Name'Access,
           Requires_Range => False,
           Requires_Text  => True));

   function Stable_Name (Kind : Text_Edit_Kind) return String is
     (Metadata (Kind).Stable_Name.all);

   function Exposes_Text
     (Policy : Protected_Text_Policy)
      return Boolean is
     (A11y.Text.Classification.Exposes_Text (Policy))
   with SPARK_Mode => On;

   function Is_Protected
     (Policy : Protected_Text_Policy)
      return Boolean is
     (A11y.Text.Classification.Is_Protected (Policy))
   with SPARK_Mode => On;

   function Edit_Requires_Range
     (Kind : Text_Edit_Kind)
      return Boolean is
     (A11y.Text.Classification.Edit_Requires_Range (Kind))
   with SPARK_Mode => On;

   function Edit_Requires_Text
     (Kind : Text_Edit_Kind)
      return Boolean is
     (A11y.Text.Classification.Edit_Requires_Text (Kind))
   with SPARK_Mode => On;

   function Edit_Requires_Nonempty_Range
     (Kind : Text_Edit_Kind)
      return Boolean is
     (A11y.Text.Classification.Edit_Requires_Nonempty_Range (Kind))
   with SPARK_Mode => On;

   function Edit_Span_Count_Allowed
     (Kind  : Text_Edit_Kind;
      Count : Natural)
      return Boolean is
     (A11y.Text.Classification.Edit_Span_Count_Allowed (Kind, Count))
   with SPARK_Mode => On;

   function Edit_Allowed_By_Policy
     (Policy    : Protected_Text_Policy;
      Read_Only : Boolean)
      return Boolean is
     (A11y.Text.Classification.Edit_Allowed_By_Policy (Policy, Read_Only))
   with SPARK_Mode => On;

   function Edit_Policy_Status
     (Policy    : Protected_Text_Policy;
      Read_Only : Boolean)
      return A11y.Results.Status_Code is
     (A11y.Text.Classification.Edit_Policy_Status (Policy, Read_Only))
   with SPARK_Mode => On;

   function Configured_Text_Limit
     (Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Natural;

   function Code_Point_Position (Index : Natural) return Text_Position is
     (Code_Point_Index => Index, Valid => True)
   with SPARK_Mode => On;

   function Is_Combining_Mark (Ch : Wide_Wide_Character) return Boolean
   with SPARK_Mode => On
   is
      Code : constant Natural := Wide_Wide_Character'Pos (Ch);
   begin
      return
        (Code in 16#0300# .. 16#036F#)
        or else (Code in 16#1AB0# .. 16#1AFF#)
        or else (Code in 16#1DC0# .. 16#1DFF#)
        or else (Code in 16#20D0# .. 16#20FF#)
        or else (Code in 16#FE20# .. 16#FE2F#);
   end Is_Combining_Mark;

   function Is_Variation_Selector (Ch : Wide_Wide_Character) return Boolean
   with SPARK_Mode => On
   is
      Code : constant Natural := Wide_Wide_Character'Pos (Ch);
   begin
      return
        (Code in 16#FE00# .. 16#FE0F#)
        or else (Code in 16#E0100# .. 16#E01EF#);
   end Is_Variation_Selector;

   function Is_Emoji_Modifier (Ch : Wide_Wide_Character) return Boolean
   with SPARK_Mode => On
   is
      Code : constant Natural := Wide_Wide_Character'Pos (Ch);
   begin
      return Code in 16#1F3FB# .. 16#1F3FF#;
   end Is_Emoji_Modifier;

   function Is_Regional_Indicator (Ch : Wide_Wide_Character) return Boolean
   with SPARK_Mode => On
   is
      Code : constant Natural := Wide_Wide_Character'Pos (Ch);
   begin
      return Code in 16#1F1E6# .. 16#1F1FF#;
   end Is_Regional_Indicator;

   function Is_Extender (Ch : Wide_Wide_Character) return Boolean
   with SPARK_Mode => On
   is
   begin
      return Is_Combining_Mark (Ch)
        or else Is_Variation_Selector (Ch)
        or else Is_Emoji_Modifier (Ch);
   end Is_Extender;

   function Is_Zero_Width_Joiner (Ch : Wide_Wide_Character) return Boolean
   with SPARK_Mode => On
   is
   begin
      return Wide_Wide_Character'Pos (Ch) = 16#200D#;
   end Is_Zero_Width_Joiner;

   function Cluster_Length
     (Content : Wide_Wide_String;
      First   : Positive)
      return Natural
   is
      Cursor : Natural := First + 1;
      Regional_Count : Natural :=
        (if Is_Regional_Indicator (Content (First)) then 1 else 0);
   begin
      while Cursor <= Content'Last loop
         if Is_Extender (Content (Cursor)) then
            Cursor := Cursor + 1;
         elsif Is_Zero_Width_Joiner (Content (Cursor))
           and then Cursor < Content'Last
         then
            Cursor := Cursor + 2;
            while Cursor <= Content'Last
              and then Is_Extender (Content (Cursor))
            loop
               Cursor := Cursor + 1;
            end loop;
         elsif Regional_Count = 1
           and then Is_Regional_Indicator (Content (Cursor))
         then
            Cursor := Cursor + 1;
            Regional_Count := 2;
         else
            exit;
         end if;
      end loop;

      return Cursor - First;
   end Cluster_Length;

   function Grapheme_Cluster_Count
     (Content : Wide_Wide_String)
      return Natural
   is
      Cursor : Natural := Content'First;
      Count  : Natural := 0;
   begin
      while Cursor <= Content'Last loop
         Count := Count + 1;
         Cursor := Cursor + Cluster_Length (Content, Cursor);
      end loop;

      return Count;
   end Grapheme_Cluster_Count;

   function Grapheme_Cluster_Range
     (Content : Wide_Wide_String;
      Start   : Natural;
      Count   : Natural;
      Result  : out A11y.Results.Result)
      return Text_Range is
   begin
      return Grapheme_Cluster_Range
        (Content, Start, Count, A11y.Resource_Limits.Default_Config, Result);
   end Grapheme_Cluster_Range;

   function Grapheme_Cluster_Range
     (Content : Wide_Wide_String;
      Start   : Natural;
      Count   : Natural;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Text_Range
   is
      Limit : constant Natural := Configured_Text_Limit (Limits, Result);
      Cursor : Natural := Content'First;
      Cluster_Index : Natural := 0;
      Code_Point_Start : Natural := 0;
      Code_Point_Count : Natural := 0;
      Cluster_Size : Natural;
   begin
      if A11y.Results.Failed (Result) then
         return Empty_Range;
      elsif Count > Limit then
         Result := (Status => A11y.Results.Resource_Limit);
         return Empty_Range;
      elsif Count > Natural'Last - Start then
         Result := (Status => A11y.Results.Invalid_Range);
         return Empty_Range;
      end if;

      while Cursor <= Content'Last and then Cluster_Index < Start loop
         Cursor := Cursor + Cluster_Length (Content, Cursor);
         Cluster_Index := Cluster_Index + 1;
      end loop;

      if Cluster_Index /= Start then
         Result := (Status => A11y.Results.Invalid_Range);
         return Empty_Range;
      end if;

      Code_Point_Start := Cursor - Content'First;

      while Cursor <= Content'Last and then Cluster_Index < Start + Count loop
         Cluster_Size := Cluster_Length (Content, Cursor);
         Cursor := Cursor + Cluster_Size;
         Code_Point_Count := Code_Point_Count + Cluster_Size;
         Cluster_Index := Cluster_Index + 1;
      end loop;

      if Count > Cluster_Index - Start then
         Result := (Status => A11y.Results.Invalid_Range);
         return Empty_Range;
      end if;

      Result := A11y.Results.Ok;
      return Make_Range (Code_Point_Position (Code_Point_Start), Code_Point_Count);
   end Grapheme_Cluster_Range;

   function Is_Valid (Item : Text_Position) return Boolean is
     (Item.Valid)
   with SPARK_Mode => On;

   function Index (Item : Text_Position) return Natural is
     (Item.Code_Point_Index)
   with SPARK_Mode => On;

   function First (Item : Text_Range) return Text_Position is
     (Item.First_Position)
   with SPARK_Mode => On;

   function Last (Item : Text_Range) return Text_Position is
     (if not Is_Valid (Item)
      or else Item.Range_Length >
        Natural'Last - Item.First_Position.Code_Point_Index
      then No_Position
      else Code_Point_Position
        (Item.First_Position.Code_Point_Index + Item.Range_Length))
   with SPARK_Mode => On;

   function Length (Item : Text_Range) return Natural is
     (Item.Range_Length)
   with SPARK_Mode => On;

   function Is_Valid (Item : Text_Range) return Boolean is
     (Item.First_Position.Valid
      and then Item.Range_Length <=
        Natural'Last - Item.First_Position.Code_Point_Index)
   with SPARK_Mode => On;

   function Is_Within
     (Content_Length : Natural;
      Position       : Text_Position)
      return Boolean is
     (Is_Valid (Position)
      and then Index (Position) <= Content_Length)
   with SPARK_Mode => On;

   function Is_Within
     (Content_Length : Natural;
      Span           : Text_Range)
      return Boolean is
     (Is_Valid (Span)
      and then Index (First (Span)) <= Content_Length
      and then Length (Span) <= Content_Length - Index (First (Span)))
   with SPARK_Mode => On;

   function Make_Range (First, Last : Text_Position) return Text_Range is
     (if not First.Valid or else not Last.Valid
      or else Last.Code_Point_Index < First.Code_Point_Index
      then Empty_Range
      else
        (First_Position => First,
         Range_Length => Last.Code_Point_Index - First.Code_Point_Index))
   with SPARK_Mode => On;

   function Make_Range
     (First  : Text_Position;
      Length : Natural)
     return Text_Range is
     (if not First.Valid
      or else Length > Natural'Last - First.Code_Point_Index
      then Empty_Range
      else (First_Position => First, Range_Length => Length))
   with SPARK_Mode => On;

   function Configured_Text_Limit
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

      Limit :=
        Natural
          (A11y.Resource_Limits.Value
             (Limits, A11y.Resource_Limits.Text_Returned));
      if Limit > Max_Text_Returned then
         Result := (Status => A11y.Results.Invalid_Argument);
         return 0;
      end if;

      Result := A11y.Results.Ok;
      return Limit;
   end Configured_Text_Limit;

   function Bounded_Code_Point_Range
     (Content_Length : Natural;
      Start          : Natural;
      Count          : Natural;
      Result         : out A11y.Results.Result)
      return Text_Range is
   begin
      return Bounded_Code_Point_Range
        (Content_Length, Start, Count, A11y.Resource_Limits.Default_Config,
         Result);
   end Bounded_Code_Point_Range;

   function Bounded_Code_Point_Range
     (Content_Length : Natural;
      Start          : Natural;
      Count          : Natural;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Result         : out A11y.Results.Result)
      return Text_Range
   is
      Limit : constant Natural := Configured_Text_Limit (Limits, Result);
   begin
      if A11y.Results.Failed (Result) then
         return Empty_Range;
      elsif Count > Limit then
         Result := (Status => A11y.Results.Resource_Limit);
         return Empty_Range;
      elsif Start > Content_Length then
         Result := (Status => A11y.Results.Invalid_Range);
         return Empty_Range;
      elsif Count > Content_Length - Start then
         Result := (Status => A11y.Results.Invalid_Range);
         return Empty_Range;
      end if;

      Result := A11y.Results.Ok;
      return Make_Range (Code_Point_Position (Start), Count);
   end Bounded_Code_Point_Range;

   function Slice
     (Content : Wide_Wide_String;
      Span    : Text_Range;
      Policy  : Protected_Text_Policy;
      Result  : out A11y.Results.Result)
      return Ada.Strings.Wide_Wide_Unbounded.Unbounded_Wide_Wide_String
   is
   begin
      return Slice
        (Content, Span, Policy, A11y.Resource_Limits.Default_Config, Result);
   end Slice;

   function Slice
     (Content : Wide_Wide_String;
      Span    : Text_Range;
      Policy  : Protected_Text_Policy;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Ada.Strings.Wide_Wide_Unbounded.Unbounded_Wide_Wide_String
   is
      Limit : Natural;
   begin
      if not Exposes_Text (Policy) then
         Result := (Status => A11y.Results.Permission_Denied);
         return Null_Unbounded_Wide_Wide_String;
      end if;

      if not Is_Valid (Span) then
         Result := (Status => A11y.Results.Invalid_Range);
         return Null_Unbounded_Wide_Wide_String;
      end if;

      Limit := Configured_Text_Limit (Limits, Result);
      if A11y.Results.Failed (Result) then
         return Null_Unbounded_Wide_Wide_String;
      end if;

      if Length (Span) > Limit then
         Result := (Status => A11y.Results.Resource_Limit);
         return Null_Unbounded_Wide_Wide_String;
      end if;

      if Length (Span) = 0 then
         Result := A11y.Results.Ok;
         return Null_Unbounded_Wide_Wide_String;
      end if;

      declare
         Offset : constant Natural := Index (First (Span));
      begin
         if Offset >= Content'Length
           or else Length (Span) > Content'Length - Offset
         then
            Result := (Status => A11y.Results.Invalid_Range);
            return Null_Unbounded_Wide_Wide_String;
         end if;

         declare
            Start : constant Natural := Content'First + Offset;
            Stop  : constant Natural := Start + Length (Span) - 1;
         begin
            Result := A11y.Results.Ok;
            return To_Unbounded_Wide_Wide_String (Content (Start .. Stop));
         end;
      end;
   end Slice;

   function UTF_16_Units
     (Content : Wide_Wide_String;
      Span    : Text_Range;
      Result  : out A11y.Results.Result)
      return Natural
   is
      Units : Natural := 0;
   begin
      if not Is_Valid (Span) then
         Result := (Status => A11y.Results.Invalid_Range);
         return 0;
      end if;

      if Length (Span) = 0 then
         Result := A11y.Results.Ok;
         return 0;
      end if;

      declare
         Offset : constant Natural := Index (First (Span));
      begin
         if Offset >= Content'Length
           or else Length (Span) > Content'Length - Offset
         then
            Result := (Status => A11y.Results.Invalid_Range);
            return 0;
         end if;

         declare
            Start : constant Natural := Content'First + Offset;
            Stop  : constant Natural := Start + Length (Span) - 1;
         begin
            for Ch of Content (Start .. Stop) loop
               if Wide_Wide_Character'Pos (Ch) <= 16#FFFF# then
                  Units := Units + 1;
               else
                  Units := Units + 2;
               end if;
            end loop;
         end;
      end;

      Result := A11y.Results.Ok;
      return Units;
   end UTF_16_Units;

   function Slice_Grapheme_Clusters
     (Content : Wide_Wide_String;
      Start   : Natural;
      Count   : Natural;
      Policy  : Protected_Text_Policy;
      Result  : out A11y.Results.Result)
      return Ada.Strings.Wide_Wide_Unbounded.Unbounded_Wide_Wide_String
   is
   begin
      return Slice_Grapheme_Clusters
        (Content, Start, Count, Policy,
         A11y.Resource_Limits.Default_Config, Result);
   end Slice_Grapheme_Clusters;

   function Slice_Grapheme_Clusters
     (Content : Wide_Wide_String;
      Start   : Natural;
      Count   : Natural;
      Policy  : Protected_Text_Policy;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Ada.Strings.Wide_Wide_Unbounded.Unbounded_Wide_Wide_String
   is
      Span : Text_Range;
   begin
      if not Exposes_Text (Policy) then
         Result := (Status => A11y.Results.Permission_Denied);
         return Null_Unbounded_Wide_Wide_String;
      end if;

      Span := Grapheme_Cluster_Range (Content, Start, Count, Limits, Result);
      if A11y.Results.Failed (Result) then
         return Null_Unbounded_Wide_Wide_String;
      end if;

      return Slice (Content, Span, Policy, Limits, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Null_Unbounded_Wide_Wide_String;
   end Slice_Grapheme_Clusters;

   function Validate_Edit_Request
     (Content_Length : Natural;
      Kind           : Text_Edit_Kind;
      Start          : Natural;
      Count          : Natural;
      Replacement    : Wide_Wide_String;
      Policy         : Protected_Text_Policy;
      Read_Only      : Boolean;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Result         : out A11y.Results.Result)
      return Text_Edit_Request
   is
      Limit : Natural;
      Span  : Text_Range := Empty_Range;
   begin
      if not Exposes_Text (Policy) then
         Result := (Status => A11y.Results.Permission_Denied);
         return
           (Kind => Kind,
            Span => Empty_Range,
            Text => Ada.Strings.Wide_Wide_Unbounded.Null_Unbounded_Wide_Wide_String);
      elsif Read_Only then
         Result := (Status => A11y.Results.Read_Only);
         return
           (Kind => Kind,
            Span => Empty_Range,
            Text => Ada.Strings.Wide_Wide_Unbounded.Null_Unbounded_Wide_Wide_String);
      end if;

      Limit := Configured_Text_Limit (Limits, Result);
      if A11y.Results.Failed (Result) then
         return
           (Kind => Kind,
            Span => Empty_Range,
            Text => Ada.Strings.Wide_Wide_Unbounded.Null_Unbounded_Wide_Wide_String);
      elsif Replacement'Length > Limit then
         Result := (Status => A11y.Results.Resource_Limit);
         return
           (Kind => Kind,
            Span => Empty_Range,
            Text => Ada.Strings.Wide_Wide_Unbounded.Null_Unbounded_Wide_Wide_String);
      end if;

      case Kind is
         when Set_Text =>
            if Start /= 0 or else Count /= 0 then
               Result := (Status => A11y.Results.Invalid_Range);
               return
                 (Kind => Kind,
                  Span => Empty_Range,
                  Text => Ada.Strings.Wide_Wide_Unbounded.Null_Unbounded_Wide_Wide_String);
            end if;
            Result := A11y.Results.Ok;
         when Insert_Text =>
            Span := Bounded_Code_Point_Range
              (Content_Length, Start, 0, Limits, Result);
            if A11y.Results.Failed (Result) then
               return
                 (Kind => Kind,
                  Span => Empty_Range,
                  Text => Ada.Strings.Wide_Wide_Unbounded.Null_Unbounded_Wide_Wide_String);
            elsif Count /= 0 then
               Result := (Status => A11y.Results.Invalid_Range);
               return
                 (Kind => Kind,
                  Span => Empty_Range,
                  Text => Ada.Strings.Wide_Wide_Unbounded.Null_Unbounded_Wide_Wide_String);
            elsif Replacement'Length = 0 then
               Result := (Status => A11y.Results.Invalid_Argument);
               return
                 (Kind => Kind,
                  Span => Empty_Range,
                  Text => Ada.Strings.Wide_Wide_Unbounded.Null_Unbounded_Wide_Wide_String);
            end if;
         when Delete_Text =>
            if Count = 0 then
               Result := (Status => A11y.Results.Invalid_Range);
               return
                 (Kind => Kind,
                  Span => Empty_Range,
                  Text => Ada.Strings.Wide_Wide_Unbounded.Null_Unbounded_Wide_Wide_String);
            end if;
            Span := Bounded_Code_Point_Range
              (Content_Length, Start, Count, Limits, Result);
            if A11y.Results.Failed (Result) then
               return
                 (Kind => Kind,
                  Span => Empty_Range,
                  Text => Ada.Strings.Wide_Wide_Unbounded.Null_Unbounded_Wide_Wide_String);
            end if;
         when Replace_Text =>
            Span := Bounded_Code_Point_Range
              (Content_Length, Start, Count, Limits, Result);
            if A11y.Results.Failed (Result) then
               return
                 (Kind => Kind,
                  Span => Empty_Range,
                  Text => Ada.Strings.Wide_Wide_Unbounded.Null_Unbounded_Wide_Wide_String);
            elsif Replacement'Length = 0 then
               Result := (Status => A11y.Results.Invalid_Argument);
               return
                 (Kind => Kind,
                  Span => Empty_Range,
                  Text => Ada.Strings.Wide_Wide_Unbounded.Null_Unbounded_Wide_Wide_String);
            end if;
      end case;

      return
        (Kind => Kind,
         Span => Span,
         Text => Ada.Strings.Wide_Wide_Unbounded.To_Unbounded_Wide_Wide_String
           (Replacement));
   end Validate_Edit_Request;

   function Validate_Edit_Request
     (Content_Length : Natural;
      Kind           : Text_Edit_Kind;
      Start          : Natural;
      Count          : Natural;
      Replacement    : Wide_Wide_String;
      Policy         : Protected_Text_Policy;
      Read_Only      : Boolean;
      Result         : out A11y.Results.Result)
      return Text_Edit_Request is
     (Validate_Edit_Request
        (Content_Length,
         Kind,
         Start,
         Count,
         Replacement,
         Policy,
         Read_Only,
         A11y.Resource_Limits.Default_Config,
         Result));

   function Validate_Grapheme_Edit_Request
     (Content     : Wide_Wide_String;
      Kind        : Text_Edit_Kind;
      Start       : Natural;
      Count       : Natural;
      Replacement : Wide_Wide_String;
      Policy      : Protected_Text_Policy;
      Read_Only   : Boolean;
      Limits      : A11y.Resource_Limits.Resource_Limit_Config;
      Result      : out A11y.Results.Result)
      return Text_Edit_Request
   is
      Span : Text_Range := Empty_Range;
   begin
      if not Exposes_Text (Policy) then
         Result := (Status => A11y.Results.Permission_Denied);
         return
           (Kind => Kind,
            Span => Empty_Range,
            Text => Null_Unbounded_Wide_Wide_String);
      elsif Read_Only then
         Result := (Status => A11y.Results.Read_Only);
         return
           (Kind => Kind,
            Span => Empty_Range,
            Text => Null_Unbounded_Wide_Wide_String);
      end if;

      if Kind = Set_Text then
         return Validate_Edit_Request
           (Content'Length,
            Kind,
            Start,
            Count,
            Replacement,
            Policy,
            Read_Only,
            Limits,
            Result);
      end if;

      Span := Grapheme_Cluster_Range
        (Content, Start, Count, Limits, Result);
      if A11y.Results.Failed (Result) then
         return
           (Kind => Kind,
            Span => Empty_Range,
            Text => Null_Unbounded_Wide_Wide_String);
      end if;

      return Validate_Edit_Request
        (Content'Length,
         Kind,
         Index (First (Span)),
         Length (Span),
         Replacement,
         Policy,
         Read_Only,
         Limits,
         Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Kind => Kind,
            Span => Empty_Range,
            Text => Null_Unbounded_Wide_Wide_String);
   end Validate_Grapheme_Edit_Request;

   function Validate_Grapheme_Edit_Request
     (Content     : Wide_Wide_String;
      Kind        : Text_Edit_Kind;
      Start       : Natural;
      Count       : Natural;
      Replacement : Wide_Wide_String;
      Policy      : Protected_Text_Policy;
      Read_Only   : Boolean;
      Result      : out A11y.Results.Result)
      return Text_Edit_Request is
     (Validate_Grapheme_Edit_Request
        (Content,
         Kind,
         Start,
         Count,
         Replacement,
         Policy,
         Read_Only,
         A11y.Resource_Limits.Default_Config,
         Result));

   function Text_Range_Safely
     (Self   : Text_Provider'Class;
      Start  : Natural;
      Count  : Natural;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Ada.Strings.Wide_Wide_Unbounded.Unbounded_Wide_Wide_String
   is
      Span : Text_Range;
      Text : Ada.Strings.Wide_Wide_Unbounded.Unbounded_Wide_Wide_String;
   begin
      if not Exposes_Text (Self.Protection) then
         Result := (Status => A11y.Results.Permission_Denied);
         return Null_Unbounded_Wide_Wide_String;
      end if;

      Span := Bounded_Code_Point_Range
        (Self.Character_Count, Start, Count, Limits, Result);
      if A11y.Results.Failed (Result) then
         return Null_Unbounded_Wide_Wide_String;
      end if;

      Text := Self.Range_Text (Span, Result);
      if A11y.Results.Failed (Result) then
         return Null_Unbounded_Wide_Wide_String;
      elsif Ada.Strings.Wide_Wide_Unbounded.Length (Text) > Count then
         Result := (Status => A11y.Results.Invalid_State);
         return Null_Unbounded_Wide_Wide_String;
      end if;

      return Text;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Null_Unbounded_Wide_Wide_String;
   end Text_Range_Safely;

   function Text_Range_Safely
     (Self   : Text_Provider'Class;
      Start  : Natural;
      Count  : Natural;
      Result : out A11y.Results.Result)
      return Ada.Strings.Wide_Wide_Unbounded.Unbounded_Wide_Wide_String is
     (Text_Range_Safely
        (Self, Start, Count, A11y.Resource_Limits.Default_Config, Result));

   function Apply_Edit_Safely
     (Self        : in out Editable_Text_Provider'Class;
      Node        : A11y.Node_Ids.Node_Id;
      Kind        : Text_Edit_Kind;
      Start       : Natural;
      Count       : Natural;
      Replacement : Wide_Wide_String;
      Limits      : A11y.Resource_Limits.Resource_Limit_Config)
      return A11y.Results.Result
   is
      Result : A11y.Results.Result;
      Request : Text_Edit_Request;
      Policy : Protected_Text_Policy;
   begin
      if not A11y.Node_Ids.Is_Valid (Node) then
         return (Status => A11y.Results.Node_Unavailable);
      end if;

      Policy := Self.Protection;
      if not Exposes_Text (Policy) then
         return (Status => A11y.Results.Permission_Denied);
      elsif Self.Is_Read_Only then
         return (Status => A11y.Results.Read_Only);
      end if;

      Request :=
        Validate_Edit_Request
          (Self.Character_Count,
           Kind,
           Start,
           Count,
           Replacement,
           Policy,
           Read_Only => False,
           Limits => Limits,
           Result => Result);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      return Self.Apply_Edit (Node, Request);
   exception
      when others =>
         return (Status => A11y.Results.Internal_Error);
   end Apply_Edit_Safely;

   function Apply_Edit_Safely
     (Self        : in out Editable_Text_Provider'Class;
      Node        : A11y.Node_Ids.Node_Id;
      Kind        : Text_Edit_Kind;
      Start       : Natural;
      Count       : Natural;
      Replacement : Wide_Wide_String)
      return A11y.Results.Result is
     (Apply_Edit_Safely
        (Self,
         Node,
         Kind,
         Start,
         Count,
         Replacement,
         A11y.Resource_Limits.Default_Config));

end A11y.Text;
