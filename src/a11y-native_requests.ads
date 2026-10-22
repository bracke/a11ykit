with A11y.Node_Ids;

--  What a screen reader asked the application to do: activate an object (an
--  invoke, a press), move the focus to it, or select it -- which is not an
--  activation: selecting a file must not open it. The Windows and macOS providers
--  record a request they have accepted; the application takes the requests
--  from its event loop and carries them out, since only it can.
package A11y.Native_Requests is

   type Request_Kind is (Activate, Focus, Select_Item);

   type Request is record
      Kind : Request_Kind := Activate;
      Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
   end record;

   --  Record an accepted request; the oldest are kept when the queue is full.
   procedure Push (Item : Request);

   --  The oldest request not yet taken, if any.
   function Pop (Item : out Request) return Boolean;

end A11y.Native_Requests;
