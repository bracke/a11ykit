package A11y.Live_Regions.Classification is
   pragma SPARK_Mode (On);

   function Is_Externally_Announced
     (Setting : Live_Setting)
      return Standard.Boolean
   with
     Global => null,
     Post =>
       Is_Externally_Announced'Result =
         (Setting in Polite | Assertive);

   function Is_Interruptive
     (Setting : Live_Setting)
      return Standard.Boolean
   with
     Global => null,
     Post => Is_Interruptive'Result = (Setting = Assertive);

   function Has_Relevant_Changes
     (Set : Relevant_Change_Set)
      return Standard.Boolean
   with
     Global => null,
     Post =>
       Has_Relevant_Changes'Result =
         (Set (Additions) or else Set (Removals) or else Set (Text));

   function Relevant_Count
     (Set : Relevant_Change_Set)
      return Natural
   with
     Global => null,
     Post =>
       Relevant_Count'Result =
         (0
          + (if Set (Additions) then 1 else 0)
          + (if Set (Removals) then 1 else 0)
          + (if Set (Text) then 1 else 0));

   function With_Change
     (Set    : Relevant_Change_Set;
      Change : Relevant_Change)
      return Relevant_Change_Set
   with
     Global => null,
     Post =>
       With_Change'Result (Change)
       and then
         (for all Item in Relevant_Change =>
            (if Item /= Change then With_Change'Result (Item) = Set (Item)));

   function Metadata_Is_Coherent
     (Item : Live_Region_Metadata)
      return Standard.Boolean
   with
     Global => null,
     Post =>
       Metadata_Is_Coherent'Result =
         ((Item.Setting = Off and then not Has_Relevant_Changes (Item.Relevant))
          or else
            (Item.Setting /= Off
             and then Has_Relevant_Changes (Item.Relevant)));

end A11y.Live_Regions.Classification;
