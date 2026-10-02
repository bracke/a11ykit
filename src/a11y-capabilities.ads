package A11y.Capabilities is
   pragma SPARK_Mode (On);

   type Capability is
     (Action,
      Text,
      Editable_Text,
      Value,
      Selection,
      Table,
      Document,
      Image,
      Relation,
      Live_Region,
      Surface);

   type Capability_Set is array (Capability) of Boolean;

   type Stable_Name_Access is access constant String;

   type Capability_Metadata is record
      Stable_Name : Stable_Name_Access;
   end record;

   Empty_Capability_Set : constant Capability_Set := [others => False];

   function Metadata (Item : Capability) return Capability_Metadata;

   function Stable_Name (Item : Capability) return String;

   function With_Capability
     (Base : Capability_Set;
      Item : Capability)
      return Capability_Set
     with
       SPARK_Mode => On,
       Global => null,
       Post =>
         With_Capability'Result (Item)
         and then
           (for all Other in Capability =>
              (if Other /= Item then
                 With_Capability'Result (Other) = Base (Other)));

end A11y.Capabilities;
