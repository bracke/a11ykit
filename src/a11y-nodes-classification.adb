package body A11y.Nodes.Classification is
   pragma SPARK_Mode (On);

   function Is_Externally_Live
     (State : Lifecycle_State)
      return Boolean is
     (A11y.Nodes.Is_Externally_Live (State));

   function Allows_Provider_Access
     (State : Lifecycle_State)
      return Boolean is
     (A11y.Nodes.Allows_Provider_Access (State));

   function Is_Final
     (State : Lifecycle_State)
      return Boolean is
     (A11y.Nodes.Is_Final (State));

   function Can_Transition
     (From_State : Lifecycle_State;
      To_State   : Lifecycle_State)
      return Boolean is
     (A11y.Nodes.Can_Transition (From_State, To_State));

   function Exposes_Node
     (Policy : Exposure_Policy)
      return Boolean is
     (A11y.Nodes.Exposes_Node (Policy));

   function Exposes_Descendants
     (Policy : Exposure_Policy)
      return Boolean is
     (A11y.Nodes.Exposes_Descendants (Policy));

   function Hides_Subtree
     (Policy : Exposure_Policy)
      return Boolean is
     (A11y.Nodes.Hides_Subtree (Policy));

   function Protected_Value_Query_Status
     (Role              : A11y.Roles.Role;
      Protection_Status : A11y.Properties.Property_Status;
      Protection_Value  : Boolean)
      return A11y.Properties.Property_Status is
     (A11y.Nodes.Protected_Value_Query_Status
        (Role, Protection_Status, Protection_Value));

end A11y.Nodes.Classification;
