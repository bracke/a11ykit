with A11y.Node_Ids;
with A11y.Results;

package A11y.Native_Identity is
   type Backend_Session_Id is private;

   No_Session : constant Backend_Session_Id;

   function Create_Session return Backend_Session_Id;
   function Is_Valid (Session : Backend_Session_Id) return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Is_Valid'Result = (Session /= No_Session);
   function Image (Session : Backend_Session_Id) return String;
   function To_Natural (Session : Backend_Session_Id) return Natural
   with
      SPARK_Mode => On,
      Global => null,
      Post => (if not Is_Valid (Session) then To_Natural'Result = 0);
   function From_Natural (Value : Natural) return Backend_Session_Id
   with
      SPARK_Mode => On,
      Global => null,
      Post => To_Natural (From_Natural'Result) = Value;

   Runtime_Node_Factor : constant Natural := 1_000_000;

   function Valid_Session_Value (Session_Value : Natural) return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Valid_Session_Value'Result = (Session_Value /= 0);

   function Valid_Runtime_Node_Component
     (Node_Value : Natural)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Valid_Runtime_Node_Component'Result =
          (Node_Value in 1 .. A11y.Node_Ids.Max_Node_Ids
           and then Node_Value < Runtime_Node_Factor);

   function Can_Encode_Runtime_Component
     (Session_Value : Natural;
      Node_Value    : Natural)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Can_Encode_Runtime_Component'Result =
          (Valid_Session_Value (Session_Value)
           and then Valid_Runtime_Node_Component (Node_Value)
           and then
             Session_Value <=
               (Natural'Last - Node_Value) / Runtime_Node_Factor);

   function Runtime_Component
     (Session_Value : Natural;
      Node_Value    : Natural)
      return Natural
   with
      SPARK_Mode => On,
      Global => null,
      Pre => Can_Encode_Runtime_Component (Session_Value, Node_Value),
      Post =>
        Runtime_Component'Result =
          Session_Value * Runtime_Node_Factor + Node_Value;

   function Component_Session_Value
     (Component : Natural)
      return Natural
   with
      SPARK_Mode => On,
      Global => null,
      Post => Component_Session_Value'Result = Component / Runtime_Node_Factor;

   function Component_Node_Value
     (Component : Natural)
      return Natural
   with
      SPARK_Mode => On,
      Global => null,
      Post => Component_Node_Value'Result = Component mod Runtime_Node_Factor;

   function Component_Matches_Session
     (Session_Value : Natural;
      Component     : Natural)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Component_Matches_Session'Result =
          (Valid_Session_Value (Session_Value)
           and then Component /= 0
           and then Component_Session_Value (Component) = Session_Value
           and then
             Valid_Runtime_Node_Component
               (Component_Node_Value (Component)));

   function Runtime_Identifier_Component
     (Session : Backend_Session_Id;
      Node    : A11y.Node_Ids.Node_Id;
      Result  : out A11y.Results.Result)
      return Natural;

   function Node_From_Runtime_Identifier_Component
     (Session   : Backend_Session_Id;
      Component : Natural;
      Result    : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id;

private
   type Backend_Session_Id is new Natural;
   No_Session : constant Backend_Session_Id := 0;
end A11y.Native_Identity;
