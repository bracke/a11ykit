with Ada.Containers.Vectors;

with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Relations is

   Max_Relation_Targets : constant Natural := 65_536;

   type Relation_Kind is
     (Labelled_By,
      Label_For,
      Described_By,
      Description_For,
      Controlled_By,
      Controller_For,
      Flows_To,
      Flows_From,
      Member_Of,
      Details,
      Details_For,
      Error_Message,
      Error_For,
      Active_Descendant,
      Embedded_By,
      Embeds,
      Popup_For,
      Popup_Controlled_By);

   type Relation_Metadata is record
      Stable_Name : access constant String;
      Inverse     : Relation_Kind := Labelled_By;
   end record;

   package Target_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => A11y.Node_Ids.Node_Id,
      "="          => A11y.Node_Ids."=");

   type Relation_Graph is private;

   function Metadata (Kind : Relation_Kind) return Relation_Metadata;

   function Stable_Name (Kind : Relation_Kind) return String;

   function Is_Self_Inverse
     (Kind : Relation_Kind)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Is_Self_Inverse'Result =
        (Kind in Member_Of | Active_Descendant);

   function Canonical_Inverse
     (Kind : Relation_Kind)
      return Relation_Kind
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        (case Kind is
           when Labelled_By         => Canonical_Inverse'Result = Label_For,
           when Label_For           => Canonical_Inverse'Result = Labelled_By,
           when Described_By        =>
             Canonical_Inverse'Result = Description_For,
           when Description_For     =>
             Canonical_Inverse'Result = Described_By,
           when Controlled_By       =>
             Canonical_Inverse'Result = Controller_For,
           when Controller_For      =>
             Canonical_Inverse'Result = Controlled_By,
           when Flows_To            => Canonical_Inverse'Result = Flows_From,
           when Flows_From          => Canonical_Inverse'Result = Flows_To,
           when Member_Of           => Canonical_Inverse'Result = Member_Of,
           when Details             => Canonical_Inverse'Result = Details_For,
           when Details_For         => Canonical_Inverse'Result = Details,
           when Error_Message       => Canonical_Inverse'Result = Error_For,
           when Error_For           => Canonical_Inverse'Result = Error_Message,
           when Active_Descendant   =>
             Canonical_Inverse'Result = Active_Descendant,
           when Embedded_By         => Canonical_Inverse'Result = Embeds,
           when Embeds              => Canonical_Inverse'Result = Embedded_By,
           when Popup_For           =>
             Canonical_Inverse'Result = Popup_Controlled_By,
           when Popup_Controlled_By =>
             Canonical_Inverse'Result = Popup_For);

   function Inverse (Kind : Relation_Kind) return Relation_Kind
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        (case Kind is
           when Labelled_By         => Inverse'Result = Label_For,
           when Label_For           => Inverse'Result = Labelled_By,
           when Described_By        => Inverse'Result = Description_For,
           when Description_For     => Inverse'Result = Described_By,
           when Controlled_By       => Inverse'Result = Controller_For,
           when Controller_For      => Inverse'Result = Controlled_By,
           when Flows_To            => Inverse'Result = Flows_From,
           when Flows_From          => Inverse'Result = Flows_To,
           when Member_Of           => Inverse'Result = Member_Of,
           when Details             => Inverse'Result = Details_For,
           when Details_For         => Inverse'Result = Details,
           when Error_Message       => Inverse'Result = Error_For,
           when Error_For           => Inverse'Result = Error_Message,
           when Active_Descendant   => Inverse'Result = Active_Descendant,
           when Embedded_By         => Inverse'Result = Embeds,
           when Embeds              => Inverse'Result = Embedded_By,
           when Popup_For           => Inverse'Result = Popup_Controlled_By,
           when Popup_Controlled_By => Inverse'Result = Popup_For);

   function Is_Canonical_Pair
     (Left  : Relation_Kind;
      Right : Relation_Kind)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Is_Canonical_Pair'Result =
        (Canonical_Inverse (Left) = Right
         and then Canonical_Inverse (Right) = Left);

   function Is_Label_Relation
     (Kind : Relation_Kind)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Is_Label_Relation'Result =
        (Kind in Labelled_By | Label_For);

   function Is_Description_Relation
     (Kind : Relation_Kind)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Is_Description_Relation'Result =
        (Kind in Described_By | Description_For | Error_Message | Error_For);

   function Is_Control_Relation
     (Kind : Relation_Kind)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Is_Control_Relation'Result =
        (Kind in Controlled_By | Controller_For | Popup_For
         | Popup_Controlled_By | Active_Descendant);

   function Allows_Cycles
     (Kind : Relation_Kind)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Allows_Cycles'Result =
        (Kind in Flows_To | Flows_From | Member_Of);

   function Targets
     (Self   : Relation_Graph;
      Source : A11y.Node_Ids.Node_Id;
      Kind   : Relation_Kind)
      return Target_Vectors.Vector;

   function Sources_Targeting
     (Self : Relation_Graph;
      Node : A11y.Node_Ids.Node_Id)
      return Target_Vectors.Vector;

   function Sources_Targeting
     (Self : Relation_Graph;
      Node : A11y.Node_Ids.Node_Id;
      Kind : Relation_Kind)
      return Target_Vectors.Vector;

   function Capacity (Self : Relation_Graph) return Natural;

   function Has_Cycle
     (Self : Relation_Graph;
      Kind : Relation_Kind)
      return Boolean;

   function Has_Any_Cycle (Self : Relation_Graph) return Boolean;

   procedure Configure_Limits
     (Self   : in out Relation_Graph;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result);

   procedure Can_Configure_Limits
     (Self   : Relation_Graph;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result);

   procedure Set_Capacity
     (Self     : in out Relation_Graph;
      Capacity : Natural;
      Result   : out A11y.Results.Result);

   procedure Add
     (Self   : in out Relation_Graph;
      Source : A11y.Node_Ids.Node_Id;
      Kind   : Relation_Kind;
      Target : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result);

   procedure Remove
     (Self   : in out Relation_Graph;
      Source : A11y.Node_Ids.Node_Id;
      Kind   : Relation_Kind;
      Target : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result);

   procedure Remove_Node
     (Self : in out Relation_Graph;
      Node : A11y.Node_Ids.Node_Id);

   type Relation_Provider is limited interface;

   function Relation_Targets
     (Self : Relation_Provider;
      Kind : Relation_Kind)
      return Target_Vectors.Vector is abstract;

   function Relation_Targets_Safely
     (Self      : Relation_Provider'Class;
      Kind      : Relation_Kind;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config;
      Result    : out A11y.Results.Result;
      Truncated : out Boolean)
      return Target_Vectors.Vector;

   function Relation_Targets_Safely
     (Self      : Relation_Provider'Class;
      Kind      : Relation_Kind;
      Result    : out A11y.Results.Result;
      Truncated : out Boolean)
      return Target_Vectors.Vector;

private
   type Relation_Record is record
      Source  : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Kind    : Relation_Kind := Labelled_By;
      Targets : Target_Vectors.Vector;
   end record;

   package Relation_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Relation_Record);

   type Relation_Graph is record
      Limit   : Natural := Max_Relation_Targets;
      Entries : Relation_Vectors.Vector;
   end record;

end A11y.Relations;
