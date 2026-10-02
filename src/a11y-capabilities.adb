package body A11y.Capabilities is
   pragma SPARK_Mode (On);

   Action_Name        : aliased constant String := "action";
   Text_Name          : aliased constant String := "text";
   Editable_Text_Name : aliased constant String := "editable-text";
   Value_Name         : aliased constant String := "value";
   Selection_Name     : aliased constant String := "selection";
   Table_Name         : aliased constant String := "table";
   Document_Name      : aliased constant String := "document";
   Image_Name         : aliased constant String := "image";
   Relation_Name      : aliased constant String := "relation";
   Live_Region_Name   : aliased constant String := "live-region";
   Surface_Name       : aliased constant String := "surface";

   function Metadata (Item : Capability) return Capability_Metadata is
     (case Item is
        when Action =>
          (Stable_Name => Action_Name'Access),
        when Text =>
          (Stable_Name => Text_Name'Access),
        when Editable_Text =>
          (Stable_Name => Editable_Text_Name'Access),
        when Value =>
          (Stable_Name => Value_Name'Access),
        when Selection =>
          (Stable_Name => Selection_Name'Access),
        when Table =>
          (Stable_Name => Table_Name'Access),
        when Document =>
          (Stable_Name => Document_Name'Access),
        when Image =>
          (Stable_Name => Image_Name'Access),
        when Relation =>
          (Stable_Name => Relation_Name'Access),
        when Live_Region =>
          (Stable_Name => Live_Region_Name'Access),
        when Surface =>
          (Stable_Name => Surface_Name'Access));

   function Stable_Name (Item : Capability) return String is
     (Metadata (Item).Stable_Name.all);

   function With_Capability
     (Base : Capability_Set;
      Item : Capability)
      return Capability_Set
   is
      Result : Capability_Set := Base;
   begin
      Result (Item) := True;
      return Result;
   end With_Capability;

end A11y.Capabilities;
