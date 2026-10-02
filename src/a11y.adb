package body A11y is
   pragma SPARK_Mode (On);

   function Event_Sequence_Image (Sequence : Event_Sequence) return String is
      Raw : constant String := Event_Sequence'Image (Sequence);
   begin
      return Raw (Raw'First + 1 .. Raw'Last);
   end Event_Sequence_Image;

end A11y;
