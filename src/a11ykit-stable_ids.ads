with Ada.Containers.Ordered_Maps;
with Ada.Strings.Unbounded;

with A11ykit.Tree;

--  An id for each node of a published tree that stays the node's while
--  nodes around it come and go, so a screen reader holding an object still
--  holds that item, and an item that goes is announced as itself. A node's
--  identity is its role and name under its parent's identity; it keeps the
--  id it was first given while that identity is published.
package A11ykit.Stable_Ids is

   type Id_State is private;

   --  Give Tree's nodes their ids (Tree.Ids): the id an identity had in the
   --  last publication, else one that no node had then either, so a new item
   --  never takes over the id of an item that has just gone. The first node
   --  (an application node above the windows) is always 1. Leaves Tree.Ids
   --  empty, publishing by position, should the ids run past what a tree
   --  can hold.
   procedure Assign (State : in out Id_State; Tree : in out A11ykit.Tree.Accessibility_Tree);

private

   package Id_Maps is new Ada.Containers.Ordered_Maps
     (Ada.Strings.Unbounded.Unbounded_String, Positive, Ada.Strings.Unbounded."<");

   type Id_State is record
      Id_Of_Identity : Id_Maps.Map;
      Last_Ids       : A11ykit.Tree.Index_Vectors.Vector;
   end record;

end A11ykit.Stable_Ids;
