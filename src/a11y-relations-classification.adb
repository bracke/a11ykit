package body A11y.Relations.Classification is
   pragma SPARK_Mode (On);

   function Is_Self_Inverse
     (Kind : Relation_Kind)
      return Boolean is
     (A11y.Relations.Is_Self_Inverse (Kind));

   function Canonical_Inverse
     (Kind : Relation_Kind)
      return Relation_Kind is
     (A11y.Relations.Canonical_Inverse (Kind));

   function Is_Canonical_Pair
     (Left  : Relation_Kind;
      Right : Relation_Kind)
      return Boolean is
     (A11y.Relations.Is_Canonical_Pair (Left, Right));

   function Is_Label_Relation
     (Kind : Relation_Kind)
      return Boolean is
     (A11y.Relations.Is_Label_Relation (Kind));

   function Is_Description_Relation
     (Kind : Relation_Kind)
      return Boolean is
     (A11y.Relations.Is_Description_Relation (Kind));

   function Is_Control_Relation
     (Kind : Relation_Kind)
      return Boolean is
     (A11y.Relations.Is_Control_Relation (Kind));

   function Allows_Cycles
     (Kind : Relation_Kind)
      return Boolean is
     (A11y.Relations.Allows_Cycles (Kind));

end A11y.Relations.Classification;
