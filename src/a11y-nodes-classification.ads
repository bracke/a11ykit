with A11y.Properties;
with A11y.Roles;

package A11y.Nodes.Classification is
   pragma SPARK_Mode (On);

   function Is_Externally_Live
     (State : Lifecycle_State)
      return Boolean
   with
      Global => null,
      Post => Is_Externally_Live'Result = (State = Active);

   function Allows_Provider_Access
     (State : Lifecycle_State)
      return Boolean
   with
      Global => null,
      Post => Allows_Provider_Access'Result =
        (State in Created | Attached | Active);

   function Is_Final
     (State : Lifecycle_State)
      return Boolean
   with
      Global => null,
      Post => Is_Final'Result = (State in Defunct | Removed);

   function Can_Transition
     (From_State : Lifecycle_State;
      To_State   : Lifecycle_State)
      return Boolean
   with
      Global => null,
      Post =>
        Can_Transition'Result =
          (if From_State = To_State then True
           elsif From_State = Created then
             To_State in Attached | Active | Removing | Defunct | Removed
           elsif From_State = Attached then
             To_State in Active | Removing | Defunct | Removed
           elsif From_State = Active then
             To_State in Attached | Removing | Defunct | Removed
           elsif From_State = Removing then
             To_State in Defunct | Removed
           else False);

   function Exposes_Node
     (Policy : Exposure_Policy)
      return Boolean
   with
      Global => null,
      Post => Exposes_Node'Result = (Policy = Expose_Node);

   function Exposes_Descendants
     (Policy : Exposure_Policy)
      return Boolean
   with
      Global => null,
      Post => Exposes_Descendants'Result =
        (Policy in Expose_Node | Flatten_Node | Expose_Descendants_Only);

   function Hides_Subtree
     (Policy : Exposure_Policy)
      return Boolean
   with
      Global => null,
      Post => Hides_Subtree'Result = (Policy = Hide_Node_And_Subtree);

   function Protected_Value_Query_Status
     (Role              : A11y.Roles.Role;
      Protection_Status : A11y.Properties.Property_Status;
      Protection_Value  : Boolean)
      return A11y.Properties.Property_Status
   with
      Global => null,
      Post =>
        Protected_Value_Query_Status'Result =
          (if Role = A11y.Roles.Password_Field then
             A11y.Properties.Permission_Denied
           elsif Protection_Status = A11y.Properties.Present then
             (if Protection_Value then A11y.Properties.Permission_Denied
              else A11y.Properties.Present)
           elsif Protection_Status in A11y.Properties.Unsupported
                                  | A11y.Properties.Empty
           then
             A11y.Properties.Present
           else
             Protection_Status);

end A11y.Nodes.Classification;
