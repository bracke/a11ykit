with Ada.Strings.Unbounded;

with A11y.Geometry;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Images is

   type Image_Kind is
     (Informative,
      Decorative,
      Chart,
      Diagram,
      Map,
      Canvas);

   type Image_Kind_Metadata is record
      Stable_Name      : access constant String;
      Exposed_By_Default : Boolean := True;
      Structured       : Boolean := False;
   end record;

   type Image_Metadata is record
      Kind                 : Image_Kind := Informative;
      Alternative_Text     : Ada.Strings.Unbounded.Unbounded_String;
      Long_Description     : Ada.Strings.Unbounded.Unbounded_String;
      Caption              : Ada.Strings.Unbounded.Unbounded_String;
      Intrinsic_Dimensions : A11y.Geometry.Size;
      Has_Intrinsic_Size   : Boolean := False;
   end record;

   function Metadata (Kind : Image_Kind) return Image_Kind_Metadata;

   function Stable_Name (Kind : Image_Kind) return String;

   function Exposed_By_Default
     (Kind : Image_Kind)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Exposed_By_Default'Result =
         (Kind /= Decorative);

   function Is_Structured_Kind
     (Kind : Image_Kind)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Is_Structured_Kind'Result =
         (Kind in Chart | Diagram | Map | Canvas);

   function Is_Informative_Kind
     (Kind : Image_Kind)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Is_Informative_Kind'Result =
         (Kind in Informative | Chart | Diagram | Map | Canvas);

   function Should_Expose (Item : Image_Metadata) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Should_Expose'Result = (Item.Kind /= Decorative);
   function Has_Text_Alternative (Item : Image_Metadata) return Boolean
   with
     SPARK_Mode => On,
     Global => null;
   function Has_Caption (Item : Image_Metadata) return Boolean
   with
     SPARK_Mode => On,
     Global => null;
   function Is_Structured (Item : Image_Metadata) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Is_Structured'Result = Is_Structured_Kind (Item.Kind);

   function Validate
     (Item   : Image_Metadata;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return A11y.Results.Result;

   function Validate
     (Item : Image_Metadata)
      return A11y.Results.Result;

   type Image_Provider is limited interface;

   function Current_Metadata
     (Self : Image_Provider)
      return Image_Metadata is abstract;

   function Current_Metadata_Safely
     (Self   : Image_Provider'Class;
      Result : out A11y.Results.Result)
      return Image_Metadata;

end A11y.Images;
