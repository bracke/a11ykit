with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Node_Keys is

   type Key_Registry is limited private;

   procedure Configure_Limits
     (Self   : in out Key_Registry;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result);

   procedure Bind
     (Self   : in out Key_Registry;
      Key    : String;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result);

   procedure Unbind_Key
     (Self   : in out Key_Registry;
      Key    : String;
      Result : out A11y.Results.Result);

   procedure Unbind_Node
     (Self   : in out Key_Registry;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result);

   function Lookup
     (Self : Key_Registry;
      Key  : String)
      return A11y.Node_Ids.Node_Id;

   function Count (Self : Key_Registry) return Natural;
   function Capacity (Self : Key_Registry) return Natural;

private
   type Binding is record
      Key  : Ada.Strings.Unbounded.Unbounded_String;
      Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
   end record;

   package Binding_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Binding);

   type Key_Registry is limited record
      Items : Binding_Vectors.Vector;
      Limit : Natural :=
        Natural
          (A11y.Resource_Limits.Value
             (A11y.Resource_Limits.Default_Config,
              A11y.Resource_Limits.Virtual_Node_Realization));
   end record;

end A11y.Node_Keys;
