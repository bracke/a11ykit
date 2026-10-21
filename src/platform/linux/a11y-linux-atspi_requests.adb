package body A11y.Linux.ATSPi_Requests is

   Capacity : constant := 64;

   type Request_Array is array (1 .. Capacity) of Request;

   protected Queue is
      procedure Put (Item : Request);
      procedure Take (Item : out Request; Found : out Boolean);
   private
      Items : Request_Array;
      First : Positive := 1;
      Count : Natural := 0;
   end Queue;

   protected body Queue is
      procedure Put (Item : Request) is
      begin
         if Count < Capacity then
            Items ((First + Count - 1) mod Capacity + 1) := Item;
            Count := Count + 1;
         end if;
      end Put;

      procedure Take (Item : out Request; Found : out Boolean) is
      begin
         Found := Count > 0;
         if Found then
            Item := Items (First);
            First := First mod Capacity + 1;
            Count := Count - 1;
         else
            Item := (others => <>);
         end if;
      end Take;
   end Queue;

   procedure Push (Item : Request) is
   begin
      Queue.Put (Item);
   end Push;

   function Pop (Item : out Request) return Boolean is
      Found : Boolean;
   begin
      Queue.Take (Item, Found);
      return Found;
   end Pop;

end A11y.Linux.ATSPi_Requests;
