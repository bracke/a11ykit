with A11y.Capabilities;
with A11y.Event_Queues;
with A11y.Events;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Registry;
with A11y.Relations;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Trees;

package A11y.Sessions is

   type Semantic_Session is limited private;

   procedure Configure_Limits
     (Self   : in out Semantic_Session;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result);

   procedure Create_Node
     (Self     : in out Semantic_Session;
      Provider : A11y.Registry.Node_Access;
      Id       : out A11y.Node_Ids.Node_Id;
      Result   : out A11y.Results.Result);

   procedure Create_Node_With_Capabilities
     (Self         : in out Semantic_Session;
      Provider     : A11y.Registry.Node_Access;
      Capabilities : A11y.Capabilities.Capability_Set;
      Id           : out A11y.Node_Ids.Node_Id;
      Result       : out A11y.Results.Result);

   procedure Attach_Root
     (Self   : in out Semantic_Session;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result);

   procedure Attach
     (Self   : in out Semantic_Session;
      Parent : A11y.Node_Ids.Node_Id;
      Child  : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result);

   procedure Detach
     (Self   : in out Semantic_Session;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result);

   procedure Move
     (Self       : in out Semantic_Session;
      New_Parent : A11y.Node_Ids.Node_Id;
      Node       : A11y.Node_Ids.Node_Id;
      Result     : out A11y.Results.Result);

   procedure Destroy
     (Self   : in out Semantic_Session;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result);

   procedure Set_Focus
     (Self   : in out Semantic_Session;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result);

   procedure Notify_Node_Event
     (Self   : in out Semantic_Session;
      Source : A11y.Node_Ids.Node_Id;
      Kind   : A11y.Events.Event_Kind;
      Result : out A11y.Results.Result);

   function Focused_Node
     (Self : Semantic_Session)
      return A11y.Node_Ids.Node_Id;

   procedure Add_Relation
     (Self   : in out Semantic_Session;
      Source : A11y.Node_Ids.Node_Id;
      Kind   : A11y.Relations.Relation_Kind;
      Target : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result);

   procedure Remove_Relation
     (Self   : in out Semantic_Session;
      Source : A11y.Node_Ids.Node_Id;
      Kind   : A11y.Relations.Relation_Kind;
      Target : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result);

   function Relation_Targets
     (Self   : in out Semantic_Session;
      Source : A11y.Node_Ids.Node_Id;
      Kind   : A11y.Relations.Relation_Kind)
      return A11y.Relations.Target_Vectors.Vector;

   procedure Dequeue_Event
     (Self   : in out Semantic_Session;
      Event  : out A11y.Events.Event;
      Result : out A11y.Results.Result);

   procedure Peek_Event
     (Self   : Semantic_Session;
      Event  : out A11y.Events.Event;
      Result : out A11y.Results.Result);

   procedure Acknowledge_Event
     (Self     : in out Semantic_Session;
      Sequence : A11y.Event_Sequence;
      Result   : out A11y.Results.Result);

   function Is_Attached
     (Self : Semantic_Session;
      Node : A11y.Node_Ids.Node_Id)
      return Boolean;

   function Parent_Of
     (Self : Semantic_Session;
      Node : A11y.Node_Ids.Node_Id)
      return A11y.Node_Ids.Node_Id;

   procedure Exposed_Children_Of
     (Self     : in out Semantic_Session;
      Node     : A11y.Node_Ids.Node_Id;
      Children : out A11y.Trees.Child_Vectors.Vector;
      Result   : out A11y.Results.Result);

   function Exposed_Parent_Of
     (Self   : in out Semantic_Session;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id;

   procedure Registry_Snapshot
     (Self   : in out Semantic_Session;
      Node   : A11y.Node_Ids.Node_Id;
      Item   : out A11y.Registry.Entry_Snapshot;
      Result : out A11y.Results.Result);

   function Validate_Tree (Self : Semantic_Session) return A11y.Results.Result;
   function Pending_Event_Count (Self : Semantic_Session) return Natural;
   function Event_Capacity (Self : Semantic_Session) return Natural;

private
   type Semantic_Session is limited record
      Registry : A11y.Registry.Node_Registry;
      Tree     : A11y.Trees.Semantic_Tree;
      Relations : A11y.Relations.Relation_Graph;
      Focused  : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Events   : A11y.Event_Queues.Event_Queue;
      Revision : A11y.Semantic_Revision := A11y.Initial_Revision;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
   end record;
end A11y.Sessions;
