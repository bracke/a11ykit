package A11y.Relations.Classification is
   pragma SPARK_Mode (On);

   function Is_Self_Inverse
     (Kind : Relation_Kind)
      return Boolean
   with
      Global => null,
      Post => Is_Self_Inverse'Result =
        (Kind in Member_Of | Active_Descendant);

   function Canonical_Inverse
     (Kind : Relation_Kind)
      return Relation_Kind
   with
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

   function Is_Canonical_Pair
     (Left  : Relation_Kind;
      Right : Relation_Kind)
      return Boolean
   with
      Global => null,
      Post => Is_Canonical_Pair'Result =
        (Canonical_Inverse (Left) = Right
         and then Canonical_Inverse (Right) = Left);

   function Is_Label_Relation
     (Kind : Relation_Kind)
      return Boolean
   with
      Global => null,
      Post => Is_Label_Relation'Result =
        (Kind in Labelled_By | Label_For);

   function Is_Description_Relation
     (Kind : Relation_Kind)
      return Boolean
   with
      Global => null,
      Post => Is_Description_Relation'Result =
        (Kind in Described_By | Description_For | Error_Message | Error_For);

   function Is_Control_Relation
     (Kind : Relation_Kind)
      return Boolean
   with
      Global => null,
      Post => Is_Control_Relation'Result =
        (Kind in Controlled_By | Controller_For | Popup_For
         | Popup_Controlled_By | Active_Descendant);

   function Allows_Cycles
     (Kind : Relation_Kind)
      return Boolean
   with
      Global => null,
      Post => Allows_Cycles'Result =
        (Kind in Flows_To | Flows_From | Member_Of);

end A11y.Relations.Classification;
