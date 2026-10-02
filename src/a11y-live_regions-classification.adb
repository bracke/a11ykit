package body A11y.Live_Regions.Classification is
   pragma SPARK_Mode (On);

   function Is_Externally_Announced
     (Setting : Live_Setting)
      return Standard.Boolean is
     (A11y.Live_Regions.Is_Externally_Announced (Setting));

   function Is_Interruptive
     (Setting : Live_Setting)
      return Standard.Boolean is
     (A11y.Live_Regions.Is_Interruptive (Setting));

   function Has_Relevant_Changes
     (Set : Relevant_Change_Set)
      return Standard.Boolean is
     (A11y.Live_Regions.Has_Relevant_Changes (Set));

   function Relevant_Count
     (Set : Relevant_Change_Set)
      return Natural is
     (A11y.Live_Regions.Relevant_Count (Set));

   function With_Change
     (Set    : Relevant_Change_Set;
      Change : Relevant_Change)
      return Relevant_Change_Set is
     (A11y.Live_Regions.With_Change (Set, Change));

   function Metadata_Is_Coherent
     (Item : Live_Region_Metadata)
      return Standard.Boolean is
     (A11y.Live_Regions.Metadata_Is_Coherent (Item));

end A11y.Live_Regions.Classification;
