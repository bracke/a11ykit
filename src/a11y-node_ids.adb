package body A11y.Node_Ids is
   pragma SPARK_Mode (On);

   function Trimmed_Image (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      return Raw (Raw'First + 1 .. Raw'Last);
   end Trimmed_Image;

   function Is_Valid (Id : Node_Id) return Boolean is
     (Natural (Id) in 1 .. Max_Node_Ids);

   function Image (Id : Node_Id) return String is
     (if Id = No_Node then "none" else Trimmed_Image (Natural (Id)));

   function To_Natural (Id : Node_Id) return Natural is
     (Natural (Id));

   function From_Natural (Value : Natural) return Node_Id is
     (Node_Id (Value));

end A11y.Node_Ids;
