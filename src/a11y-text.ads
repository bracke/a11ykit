with Ada.Strings.Wide_Wide_Unbounded;

with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Text is

   Max_Text_Returned : constant Natural := 16_384;

   type Text_Position is private;
   type Text_Range is private;
   type Protected_Text_Policy is (Plain_Text, Protected_Text);
   type Text_Edit_Kind is
     (Insert_Text,
      Delete_Text,
      Replace_Text,
      Set_Text);

   type Protected_Text_Metadata is record
      Stable_Name : access constant String;
      Exposes_Text : Boolean := False;
   end record;

   type Text_Edit_Metadata is record
      Stable_Name    : access constant String;
      Requires_Range : Boolean := True;
      Requires_Text  : Boolean := False;
   end record;

   No_Position : constant Text_Position;
   Empty_Range : constant Text_Range;

   type Text_Edit_Request is record
      Kind : Text_Edit_Kind := Insert_Text;
      Span : Text_Range := Empty_Range;
      Text : Ada.Strings.Wide_Wide_Unbounded.Unbounded_Wide_Wide_String;
   end record;

   function Metadata
     (Policy : Protected_Text_Policy)
      return Protected_Text_Metadata;

   function Metadata (Kind : Text_Edit_Kind) return Text_Edit_Metadata;

   function Stable_Name (Policy : Protected_Text_Policy) return String;
   function Stable_Name (Kind : Text_Edit_Kind) return String;

   function Exposes_Text
     (Policy : Protected_Text_Policy)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Exposes_Text'Result = (Policy = Plain_Text);

   function Is_Protected
     (Policy : Protected_Text_Policy)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Is_Protected'Result = (Policy = Protected_Text);

   function Edit_Requires_Range
     (Kind : Text_Edit_Kind)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Edit_Requires_Range'Result = (Kind /= Set_Text);

   function Edit_Requires_Text
     (Kind : Text_Edit_Kind)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Edit_Requires_Text'Result =
        (Kind in Insert_Text | Replace_Text | Set_Text);

   function Edit_Requires_Nonempty_Range
     (Kind : Text_Edit_Kind)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Edit_Requires_Nonempty_Range'Result =
        (Kind in Delete_Text | Replace_Text);

   function Edit_Span_Count_Allowed
     (Kind  : Text_Edit_Kind;
      Count : Natural)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Edit_Span_Count_Allowed'Result =
        ((if Edit_Requires_Nonempty_Range (Kind) then Count > 0 else True)
         and then (if Kind = Set_Text then Count = 0 else True));

   function Edit_Allowed_By_Policy
     (Policy    : Protected_Text_Policy;
      Read_Only : Boolean)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Edit_Allowed_By_Policy'Result =
        (Policy = Plain_Text and then not Read_Only);

   function Edit_Policy_Status
     (Policy    : Protected_Text_Policy;
      Read_Only : Boolean)
      return A11y.Results.Status_Code
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        (if Policy = Protected_Text then
           A11y.Results."="
             (Edit_Policy_Status'Result, A11y.Results.Permission_Denied)
         elsif Read_Only then
           A11y.Results."="
             (Edit_Policy_Status'Result, A11y.Results.Read_Only)
         else
           A11y.Results."="
             (Edit_Policy_Status'Result, A11y.Results.Success));

   function Code_Point_Position (Index : Natural) return Text_Position
   with
      SPARK_Mode => On,
      Global => null;
   function Grapheme_Cluster_Count
     (Content : Wide_Wide_String)
      return Natural;
   function Grapheme_Cluster_Range
     (Content : Wide_Wide_String;
      Start   : Natural;
      Count   : Natural;
      Result  : out A11y.Results.Result)
      return Text_Range;
   function Grapheme_Cluster_Range
     (Content : Wide_Wide_String;
      Start   : Natural;
      Count   : Natural;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Text_Range;
   function Is_Valid (Item : Text_Position) return Boolean
   with
      SPARK_Mode => On,
      Global => null;
   function Index (Item : Text_Position) return Natural
   with
      SPARK_Mode => On,
      Global => null;
   function First (Item : Text_Range) return Text_Position
   with
      SPARK_Mode => On,
      Global => null;
   function Last (Item : Text_Range) return Text_Position
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        (if Is_Valid (Item)
         then Is_Valid (Last'Result)
              and then Index (Last'Result) = Index (First (Item)) + Length (Item)
         else not Is_Valid (Last'Result));
   function Length (Item : Text_Range) return Natural
   with
      SPARK_Mode => On,
      Global => null;
   function Is_Valid (Item : Text_Range) return Boolean
   with
      SPARK_Mode => On,
      Global => null;
   function Is_Within
     (Content_Length : Natural;
      Position       : Text_Position)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Is_Within'Result =
          (Is_Valid (Position) and then Index (Position) <= Content_Length);
   function Is_Within
     (Content_Length : Natural;
      Span           : Text_Range)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Is_Within'Result =
          (Is_Valid (Span)
           and then Index (First (Span)) <= Content_Length
           and then Length (Span) <= Content_Length - Index (First (Span)));
   function Make_Range (First, Last : Text_Position) return Text_Range
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        (if Is_Valid (First)
           and then Is_Valid (Last)
           and then Index (Last) >= Index (First)
         then Is_Valid (Make_Range'Result)
              and then Index (A11y.Text.First (Make_Range'Result)) =
                Index (First)
              and then Length (Make_Range'Result) =
                Index (Last) - Index (First)
         else not Is_Valid (Make_Range'Result));

   function Make_Range
     (First  : Text_Position;
      Length : Natural)
      return Text_Range
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        (if Is_Valid (First)
           and then Length <= Natural'Last - Index (First)
         then Is_Valid (Make_Range'Result)
              and then Index (A11y.Text.First (Make_Range'Result)) =
                Index (First)
              and then A11y.Text.Length (Make_Range'Result) = Length
         else not Is_Valid (Make_Range'Result));

   function Bounded_Code_Point_Range
     (Content_Length : Natural;
      Start          : Natural;
      Count          : Natural;
      Result         : out A11y.Results.Result)
      return Text_Range;

   function Bounded_Code_Point_Range
     (Content_Length : Natural;
      Start          : Natural;
      Count          : Natural;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Result         : out A11y.Results.Result)
      return Text_Range;

   function Slice
     (Content : Wide_Wide_String;
      Span    : Text_Range;
      Policy  : Protected_Text_Policy;
      Result  : out A11y.Results.Result)
      return Ada.Strings.Wide_Wide_Unbounded.Unbounded_Wide_Wide_String;

   function Slice
     (Content : Wide_Wide_String;
      Span    : Text_Range;
      Policy  : Protected_Text_Policy;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Ada.Strings.Wide_Wide_Unbounded.Unbounded_Wide_Wide_String;

   function Slice_Grapheme_Clusters
     (Content : Wide_Wide_String;
      Start   : Natural;
      Count   : Natural;
      Policy  : Protected_Text_Policy;
      Result  : out A11y.Results.Result)
      return Ada.Strings.Wide_Wide_Unbounded.Unbounded_Wide_Wide_String;

   function Slice_Grapheme_Clusters
     (Content : Wide_Wide_String;
      Start   : Natural;
      Count   : Natural;
      Policy  : Protected_Text_Policy;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Ada.Strings.Wide_Wide_Unbounded.Unbounded_Wide_Wide_String;

   function UTF_16_Units
     (Content : Wide_Wide_String;
      Span    : Text_Range;
      Result  : out A11y.Results.Result)
      return Natural;

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
      return Text_Edit_Request;

   function Validate_Edit_Request
     (Content_Length : Natural;
      Kind           : Text_Edit_Kind;
      Start          : Natural;
      Count          : Natural;
      Replacement    : Wide_Wide_String;
      Policy         : Protected_Text_Policy;
      Read_Only      : Boolean;
      Result         : out A11y.Results.Result)
      return Text_Edit_Request;

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
      return Text_Edit_Request;

   function Validate_Grapheme_Edit_Request
     (Content     : Wide_Wide_String;
      Kind        : Text_Edit_Kind;
      Start       : Natural;
      Count       : Natural;
      Replacement : Wide_Wide_String;
      Policy      : Protected_Text_Policy;
      Read_Only   : Boolean;
      Result      : out A11y.Results.Result)
      return Text_Edit_Request;

   type Text_Provider is limited interface;

   function Character_Count
     (Self : Text_Provider)
      return Natural is abstract;

   function Protection
     (Self : Text_Provider)
      return Protected_Text_Policy is abstract;

   function Range_Text
     (Self   : Text_Provider;
      Span   : Text_Range;
      Result : out A11y.Results.Result)
      return Ada.Strings.Wide_Wide_Unbounded.Unbounded_Wide_Wide_String
      is abstract;

   function Text_Range_Safely
     (Self   : Text_Provider'Class;
      Start  : Natural;
      Count  : Natural;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Ada.Strings.Wide_Wide_Unbounded.Unbounded_Wide_Wide_String;

   function Text_Range_Safely
     (Self   : Text_Provider'Class;
      Start  : Natural;
      Count  : Natural;
      Result : out A11y.Results.Result)
      return Ada.Strings.Wide_Wide_Unbounded.Unbounded_Wide_Wide_String;

   type Editable_Text_Provider is limited interface and Text_Provider;

   function Is_Read_Only
     (Self : Editable_Text_Provider)
      return Boolean is abstract;

   function Apply_Edit
     (Self    : in out Editable_Text_Provider;
      Node    : A11y.Node_Ids.Node_Id;
      Request : Text_Edit_Request)
      return A11y.Results.Result is abstract;

   function Apply_Edit_Safely
     (Self        : in out Editable_Text_Provider'Class;
      Node        : A11y.Node_Ids.Node_Id;
      Kind        : Text_Edit_Kind;
      Start       : Natural;
      Count       : Natural;
      Replacement : Wide_Wide_String;
      Limits      : A11y.Resource_Limits.Resource_Limit_Config)
      return A11y.Results.Result;

   function Apply_Edit_Safely
     (Self        : in out Editable_Text_Provider'Class;
      Node        : A11y.Node_Ids.Node_Id;
      Kind        : Text_Edit_Kind;
      Start       : Natural;
      Count       : Natural;
      Replacement : Wide_Wide_String)
      return A11y.Results.Result;

private
   type Text_Position is record
      Code_Point_Index : Natural := 0;
      Valid : Boolean := False;
   end record;

   type Text_Range is record
      First_Position : Text_Position;
      Range_Length    : Natural := 0;
   end record;

   No_Position : constant Text_Position :=
     (Code_Point_Index => 0, Valid => False);
   Empty_Range : constant Text_Range :=
     (First_Position => No_Position, Range_Length => 0);
end A11y.Text;
