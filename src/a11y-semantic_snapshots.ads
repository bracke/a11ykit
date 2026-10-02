with Ada.Containers.Vectors;

with A11y.Capabilities;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Properties;
with A11y.Results;
with A11y.Roles;
with A11y.States;

package A11y.Semantic_Snapshots is

   type Node_Metadata is record
      Present      : Boolean := False;
      Role         : A11y.Roles.Role := A11y.Roles.Custom;
      Name         : A11y.Properties.String_Property;
      Visible_Title : A11y.Properties.String_Property;
      Description  : A11y.Properties.String_Property;
      Help_Text    : A11y.Properties.String_Property;
      Placeholder  : A11y.Properties.String_Property;
      Value_Text   : A11y.Properties.String_Property;
      Protected_Value_Text : Boolean := False;
      Bounds       : A11y.Properties.Rectangle_Property;
      Semantic_Identifier : A11y.Properties.String_Property;
      Keyboard_Shortcut : A11y.Properties.String_Property;
      Locale       : A11y.Properties.String_Property;
      Orientation  : A11y.Properties.String_Property;
      Landmark     : A11y.Properties.String_Property;
      States       : A11y.States.State_Set := A11y.States.Empty_State_Set;
      Capabilities : A11y.Capabilities.Capability_Set :=
        A11y.Capabilities.Empty_Capability_Set;
      Exposure     : A11y.Nodes.Exposure_Policy := A11y.Nodes.Expose_Node;
   end record;

   type Node_Metadata_Entry is record
      Node     : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Metadata : Node_Metadata;
   end record;

   package Node_Metadata_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Node_Metadata_Entry);

   type Semantic_Snapshot is private;

   function Node_Count (Snapshot : Semantic_Snapshot) return Natural;

   function Has_Node
     (Snapshot : Semantic_Snapshot;
      Node     : A11y.Node_Ids.Node_Id)
      return Boolean;

   function Metadata
     (Snapshot : Semantic_Snapshot;
      Node     : A11y.Node_Ids.Node_Id)
      return Node_Metadata;

   procedure Set_Node
     (Snapshot     : in out Semantic_Snapshot;
      Node         : A11y.Node_Ids.Node_Id;
      Role         : A11y.Roles.Role;
      Name         : String;
      Description  : String;
      States       : A11y.States.State_Set;
      Capabilities : A11y.Capabilities.Capability_Set;
      Exposure     : A11y.Nodes.Exposure_Policy;
      Result       : out A11y.Results.Result);

   procedure Set_Node
     (Snapshot     : in out Semantic_Snapshot;
      Node         : A11y.Node_Ids.Node_Id;
      Role         : A11y.Roles.Role;
      Name         : String;
      States       : A11y.States.State_Set;
      Capabilities : A11y.Capabilities.Capability_Set;
      Exposure     : A11y.Nodes.Exposure_Policy;
      Result       : out A11y.Results.Result);

   procedure Set_Node
     (Snapshot     : in out Semantic_Snapshot;
      Node         : A11y.Node_Ids.Node_Id;
      Role         : A11y.Roles.Role;
      Name         : String;
      Description  : String;
      Help_Text    : A11y.Properties.String_Property;
      Placeholder  : A11y.Properties.String_Property;
      Value_Text   : A11y.Properties.String_Property;
      Protected_Value_Text : Boolean;
      Bounds       : A11y.Properties.Rectangle_Property;
      Semantic_Identifier : A11y.Properties.String_Property;
      Visible_Title : A11y.Properties.String_Property;
      Keyboard_Shortcut : A11y.Properties.String_Property;
      Locale       : A11y.Properties.String_Property;
      Orientation  : A11y.Properties.String_Property;
      Landmark     : A11y.Properties.String_Property;
      States       : A11y.States.State_Set;
      Capabilities : A11y.Capabilities.Capability_Set;
      Exposure     : A11y.Nodes.Exposure_Policy;
      Result       : out A11y.Results.Result);

   procedure Set_Node
     (Snapshot     : in out Semantic_Snapshot;
      Node         : A11y.Node_Ids.Node_Id;
      Role         : A11y.Roles.Role;
      Name         : String;
      Description  : String;
      Help_Text    : A11y.Properties.String_Property;
      Placeholder  : A11y.Properties.String_Property;
      Value_Text   : A11y.Properties.String_Property;
      Protected_Value_Text : Boolean;
      Bounds       : A11y.Properties.Rectangle_Property;
      States       : A11y.States.State_Set;
      Capabilities : A11y.Capabilities.Capability_Set;
      Exposure     : A11y.Nodes.Exposure_Policy;
      Result       : out A11y.Results.Result);

   procedure Set_Node
     (Snapshot     : in out Semantic_Snapshot;
      Node         : A11y.Node_Ids.Node_Id;
      Role         : A11y.Roles.Role;
      Name         : String;
      Description  : String;
      Help_Text    : A11y.Properties.String_Property;
      Placeholder  : A11y.Properties.String_Property;
      Value_Text   : A11y.Properties.String_Property;
      Protected_Value_Text : Boolean;
      States       : A11y.States.State_Set;
      Capabilities : A11y.Capabilities.Capability_Set;
      Exposure     : A11y.Nodes.Exposure_Policy;
      Result       : out A11y.Results.Result);

   procedure Clear_Node
     (Snapshot : in out Semantic_Snapshot;
      Node     : A11y.Node_Ids.Node_Id;
      Result   : out A11y.Results.Result);

   function Validate_Node
     (Snapshot : Semantic_Snapshot;
      Node     : A11y.Node_Ids.Node_Id)
      return A11y.Results.Result;

private
   function Slot_Of (Node : A11y.Node_Ids.Node_Id) return Natural is
     (A11y.Node_Ids.To_Natural (Node));

   type Semantic_Snapshot is record
      Nodes : Node_Metadata_Vectors.Vector;
   end record;

end A11y.Semantic_Snapshots;
