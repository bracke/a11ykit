with A11y.Images.Classification;

package body A11y.Images is
   use Ada.Strings.Unbounded;
   use type A11y.Geometry.Length;
   use type A11y.Resource_Limits.Limit_Value;

   Informative_Name : aliased constant String := "informative";
   Decorative_Name  : aliased constant String := "decorative";
   Chart_Name       : aliased constant String := "chart";
   Diagram_Name     : aliased constant String := "diagram";
   Map_Name         : aliased constant String := "map";
   Canvas_Name      : aliased constant String := "canvas";

   function Metadata (Kind : Image_Kind) return Image_Kind_Metadata is
     (case Kind is
        when Informative =>
          (Stable_Name => Informative_Name'Access,
           Exposed_By_Default => True,
           Structured => False),
        when Decorative =>
          (Stable_Name => Decorative_Name'Access,
           Exposed_By_Default => False,
           Structured => False),
        when Chart =>
          (Stable_Name => Chart_Name'Access,
           Exposed_By_Default => True,
           Structured => True),
        when Diagram =>
          (Stable_Name => Diagram_Name'Access,
           Exposed_By_Default => True,
           Structured => True),
        when Map =>
          (Stable_Name => Map_Name'Access,
           Exposed_By_Default => True,
           Structured => True),
        when Canvas =>
          (Stable_Name => Canvas_Name'Access,
           Exposed_By_Default => True,
           Structured => True));

   function Stable_Name (Kind : Image_Kind) return String is
     (Metadata (Kind).Stable_Name.all);

   function Exposed_By_Default
     (Kind : Image_Kind)
      return Boolean is
     (A11y.Images.Classification.Exposed_By_Default (Kind))
   with SPARK_Mode => On;

   function Is_Structured_Kind
     (Kind : Image_Kind)
      return Boolean is
     (A11y.Images.Classification.Is_Structured_Kind (Kind))
   with SPARK_Mode => On;

   function Is_Informative_Kind
     (Kind : Image_Kind)
      return Boolean is
     (A11y.Images.Classification.Is_Informative_Kind (Kind))
   with SPARK_Mode => On;

   function Should_Expose (Item : Image_Metadata) return Boolean is
     (Exposed_By_Default (Item.Kind))
   with SPARK_Mode => On;

   function Has_Text_Alternative (Item : Image_Metadata) return Boolean is
     (Length (Item.Alternative_Text) > 0
      or else Length (Item.Long_Description) > 0)
   with SPARK_Mode => On;

   function Has_Caption (Item : Image_Metadata) return Boolean is
     (Length (Item.Caption) > 0)
   with SPARK_Mode => On;

   function Is_Structured (Item : Image_Metadata) return Boolean is
     (Is_Structured_Kind (Item.Kind))
   with SPARK_Mode => On;

   function Text_Exceeds
     (Value  : Unbounded_String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return Boolean is
     (A11y.Resource_Limits.Limit_Value (Length (Value))
      > A11y.Resource_Limits.Value
          (Limits, A11y.Resource_Limits.Text_Returned))
   with SPARK_Mode => On;

   function Validate
     (Item   : Image_Metadata;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return A11y.Results.Result
   is
      Result : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
   begin
      if A11y.Results.Failed (Result) then
         return Result;
      elsif Item.Kind = Decorative
        and then (Length (Item.Alternative_Text) > 0
                  or else Length (Item.Long_Description) > 0
                  or else Length (Item.Caption) > 0)
      then
         return (Status => A11y.Results.Invalid_State);
      elsif Item.Has_Intrinsic_Size
        and then (Item.Intrinsic_Dimensions.Width = 0
                  or else Item.Intrinsic_Dimensions.Height = 0)
      then
         return (Status => A11y.Results.Invalid_Range);
      elsif Text_Exceeds (Item.Alternative_Text, Limits)
        or else Text_Exceeds (Item.Long_Description, Limits)
        or else Text_Exceeds (Item.Caption, Limits)
      then
         return (Status => A11y.Results.Resource_Limit);
      else
         return A11y.Results.Ok;
      end if;
   end Validate;

   function Validate
     (Item : Image_Metadata)
      return A11y.Results.Result is
     (Validate (Item, A11y.Resource_Limits.Default_Config));

   function Current_Metadata_Safely
     (Self   : Image_Provider'Class;
      Result : out A11y.Results.Result)
      return Image_Metadata
   is
      Item : Image_Metadata;
   begin
      Item := Self.Current_Metadata;
      Result := Validate (Item);
      if A11y.Results.Failed (Result) then
         return (Kind                 => Decorative,
                 Alternative_Text     => <>,
                 Long_Description     => <>,
                 Caption              => <>,
                 Intrinsic_Dimensions => (Width => 0, Height => 0),
                 Has_Intrinsic_Size   => False);
      end if;
      return Item;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return (Kind                 => Decorative,
                 Alternative_Text     => <>,
                 Long_Description     => <>,
                 Caption              => <>,
                 Intrinsic_Dimensions => (Width => 0, Height => 0),
                 Has_Intrinsic_Size   => False);
   end Current_Metadata_Safely;

end A11y.Images;
