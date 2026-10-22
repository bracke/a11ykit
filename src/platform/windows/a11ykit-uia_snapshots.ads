with A11ykit.Tree;

with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Results;
with A11y.Windows_Backend.UIA_Request_Router;

--  The UI Automation snapshot a published tree is answered from. Its own
--  unit, free of the native bridge, so a host without Windows can build one
--  and drive the callbacks against it the way a UI Automation client would.
package A11ykit.UIA_Snapshots is

   --  The tree's root: its first node without a parent.
   function Root_Node
     (Tree   : A11ykit.Tree.Accessibility_Tree;
      Result : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id;

   --  Fill Snapshots with Tree as Session publishes it from Root.
   procedure Build_Snapshots
     (Tree      : A11ykit.Tree.Accessibility_Tree;
      Root      : A11y.Node_Ids.Node_Id;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Snapshots : out A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Result    : out A11y.Results.Result);

end A11ykit.UIA_Snapshots;
