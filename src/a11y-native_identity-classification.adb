package body A11y.Native_Identity.Classification is
   pragma SPARK_Mode (On);

   function Valid_Session_Value (Session_Value : Natural) return Boolean is
     (A11y.Native_Identity.Valid_Session_Value (Session_Value));

   function Valid_Runtime_Node_Component
     (Node_Value : Natural)
      return Boolean is
     (A11y.Native_Identity.Valid_Runtime_Node_Component (Node_Value));

   function Can_Encode_Runtime_Component
     (Session_Value : Natural;
      Node_Value    : Natural)
      return Boolean is
     (A11y.Native_Identity.Can_Encode_Runtime_Component
        (Session_Value, Node_Value));

   function Runtime_Component
     (Session_Value : Natural;
      Node_Value    : Natural)
      return Natural is
     (A11y.Native_Identity.Runtime_Component (Session_Value, Node_Value));

   function Component_Session_Value
     (Component : Natural)
      return Natural is
     (A11y.Native_Identity.Component_Session_Value (Component));

   function Component_Node_Value
     (Component : Natural)
      return Natural is
     (A11y.Native_Identity.Component_Node_Value (Component));

   function Component_Matches_Session
     (Session_Value : Natural;
      Component     : Natural)
      return Boolean is
     (A11y.Native_Identity.Component_Matches_Session
        (Session_Value, Component));

end A11y.Native_Identity.Classification;
