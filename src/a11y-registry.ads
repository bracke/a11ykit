with A11y.Capabilities;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Registry is

   type Node_Access is access all A11y.Nodes.Accessible_Node'Class;

   type Entry_Snapshot is record
      Id           : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Lifecycle    : A11y.Nodes.Lifecycle_State := A11y.Nodes.Created;
      Parent       : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Revision     : A11y.Semantic_Revision := A11y.Initial_Revision;
      Capabilities : A11y.Capabilities.Capability_Set :=
        A11y.Capabilities.Empty_Capability_Set;
      Pinned       : Natural := 0;
      Pin_Limit    : Natural := 0;
      Tombstone    : Boolean := False;
   end record;

   type Pin is limited private;

   Max_Nodes : constant Natural := A11y.Node_Ids.Max_Node_Ids;

   type Registry_Record is record
      Used         : Boolean := False;
      Provider     : Node_Access := null;
      Lifecycle    : A11y.Nodes.Lifecycle_State := A11y.Nodes.Created;
      Parent       : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Revision     : A11y.Semantic_Revision := A11y.Initial_Revision;
      Capabilities : A11y.Capabilities.Capability_Set :=
        A11y.Capabilities.Empty_Capability_Set;
      Pinned       : Natural := 0;
      Tombstone    : Boolean := False;
   end record;

   type Registry_Table is array (Positive range 1 .. Max_Nodes) of Registry_Record;

   protected type Node_Registry is
      procedure Can_Configure_Limits
        (Limits : A11y.Resource_Limits.Resource_Limit_Config;
         Result : out A11y.Results.Result);
      procedure Configure_Limits
        (Limits : A11y.Resource_Limits.Resource_Limit_Config;
         Result : out A11y.Results.Result);
      procedure Allocate (Id : out A11y.Node_Ids.Node_Id);
      procedure Register
        (Id       : A11y.Node_Ids.Node_Id;
         Provider : Node_Access;
         Result   : out A11y.Results.Result;
         Capabilities : A11y.Capabilities.Capability_Set :=
           A11y.Capabilities.Empty_Capability_Set);
      procedure Set_Lifecycle
        (Id     : A11y.Node_Ids.Node_Id;
         State  : A11y.Nodes.Lifecycle_State;
         Result : out A11y.Results.Result);
      procedure Set_Parent
        (Id     : A11y.Node_Ids.Node_Id;
         Parent : A11y.Node_Ids.Node_Id;
         Result : out A11y.Results.Result);
      procedure Lookup
        (Id       : A11y.Node_Ids.Node_Id;
         Provider : out Node_Access;
         State    : out A11y.Nodes.Lifecycle_State;
         Result   : out A11y.Results.Result);
      procedure Snapshot
        (Id     : A11y.Node_Ids.Node_Id;
         Item   : out Entry_Snapshot;
         Result : out A11y.Results.Result);
      procedure Pin_Node
        (Id     : A11y.Node_Ids.Node_Id;
         Token  : out Pin;
         Result : out A11y.Results.Result);
      procedure Unpin_Node (Token : in out Pin);
      procedure Remove
        (Id     : A11y.Node_Ids.Node_Id;
         Result : out A11y.Results.Result);
   private
      Next_Id : Natural := 1;
      Pin_Limit : Natural := Natural
        (A11y.Resource_Limits.Value
           (A11y.Resource_Limits.Default_Config,
            A11y.Resource_Limits.Outstanding_Callbacks));
      Records : Registry_Table;
   end Node_Registry;

private
   type Pin is record
      Id     : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Active : Boolean := False;
   end record;
end A11y.Registry;
