with A11y.Node_Ids;

--  What a screen reader asked the application to do: activate an object
--  (Action.DoAction) or move the focus to it (Component.GrabFocus). The
--  D-Bus side records a request it has accepted; the application takes the
--  requests from its event loop and carries them out, since only it can.
package A11y.Linux.ATSPi_Requests is

   type Request_Kind is (Activate, Focus);

   type Request is record
      Kind : Request_Kind := Activate;
      Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
   end record;

   --  Record an accepted request; the oldest are kept when the queue is full.
   procedure Push (Item : Request);

   --  The oldest request not yet taken, if any.
   function Pop (Item : out Request) return Boolean;

end A11y.Linux.ATSPi_Requests;
