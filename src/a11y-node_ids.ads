package A11y.Node_Ids is
   pragma SPARK_Mode (On);

   Max_Node_Ids : constant Natural := 65_536;

   type Node_Id is private;

   No_Node : constant Node_Id;

   function Is_Valid (Id : Node_Id) return Boolean
     with
       Global => null,
       Post =>
         Is_Valid'Result =
           (To_Natural (Id) in 1 .. Max_Node_Ids);

   function Image (Id : Node_Id) return String;

   function To_Natural (Id : Node_Id) return Natural
     with
       Global => null,
       Post =>
         (if Id = No_Node then To_Natural'Result = 0);

   function From_Natural (Value : Natural) return Node_Id
     with
       Global => null,
       Post =>
         To_Natural (From_Natural'Result) = Value
         and then Is_Valid (From_Natural'Result) =
           (Value in 1 .. Max_Node_Ids);

private
   type Node_Id is new Natural;
   No_Node : constant Node_Id := 0;
end A11y.Node_Ids;
