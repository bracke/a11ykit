package body A11y.Registry is
   use type A11y.Node_Ids.Node_Id;

   protected body Node_Registry is
      procedure Can_Configure_Limits
        (Limits : A11y.Resource_Limits.Resource_Limit_Config;
         Result : out A11y.Results.Result)
      is
         Candidate : Natural;
      begin
         Result := A11y.Resource_Limits.Validate (Limits);
         if A11y.Results.Failed (Result) then
            return;
         end if;

         Candidate := Natural
           (A11y.Resource_Limits.Value
              (Limits, A11y.Resource_Limits.Outstanding_Callbacks));

         for Index in Records'Range loop
            if Records (Index).Used
              and then Records (Index).Pinned > Candidate
            then
               Result := (Status => A11y.Results.Invalid_State);
               return;
            end if;
         end loop;

         Result := A11y.Results.Ok;
      end Can_Configure_Limits;

      procedure Configure_Limits
        (Limits : A11y.Resource_Limits.Resource_Limit_Config;
         Result : out A11y.Results.Result)
      is
      begin
         Can_Configure_Limits (Limits, Result);
         if A11y.Results.Succeeded (Result) then
            Pin_Limit := Natural
              (A11y.Resource_Limits.Value
                 (Limits, A11y.Resource_Limits.Outstanding_Callbacks));
         end if;
      end Configure_Limits;

      procedure Allocate (Id : out A11y.Node_Ids.Node_Id) is
      begin
         if Next_Id > Max_Nodes then
            Id := A11y.Node_Ids.No_Node;
         else
            Id := A11y.Node_Ids.From_Natural (Next_Id);
            Next_Id := Next_Id + 1;
         end if;
      end Allocate;

      procedure Register
        (Id       : A11y.Node_Ids.Node_Id;
         Provider : Node_Access;
         Result   : out A11y.Results.Result;
         Capabilities : A11y.Capabilities.Capability_Set :=
           A11y.Capabilities.Empty_Capability_Set)
      is
         Slot : constant Natural := A11y.Node_Ids.To_Natural (Id);
      begin
         if Slot = 0 or else Slot >= Next_Id or else Slot > Max_Nodes then
            Result := (Status => A11y.Results.Invalid_Argument);
         elsif Records (Slot).Used then
            Result := (Status => A11y.Results.Invalid_State);
         else
            Records (Slot).Used := True;
            Records (Slot).Provider := Provider;
            Records (Slot).Lifecycle := A11y.Nodes.Created;
            Records (Slot).Parent := A11y.Node_Ids.No_Node;
            Records (Slot).Revision := A11y.Initial_Revision;
            Records (Slot).Capabilities := Capabilities;
            Records (Slot).Tombstone := False;
            Records (Slot).Pinned := 0;
            Result := A11y.Results.Ok;
         end if;
      end Register;

      procedure Set_Lifecycle
        (Id     : A11y.Node_Ids.Node_Id;
         State  : A11y.Nodes.Lifecycle_State;
         Result : out A11y.Results.Result)
      is
         Slot : constant Natural := A11y.Node_Ids.To_Natural (Id);
         Transition : A11y.Results.Result;
      begin
         if Slot = 0 or else Slot >= Next_Id or else not Records (Slot).Used then
            Result := (Status => A11y.Results.Node_Unavailable);
         else
            Transition := A11y.Nodes.Validate_Transition
              (Records (Slot).Lifecycle, State);
            if A11y.Results.Failed (Transition) then
               Result := Transition;
               return;
            end if;

            Records (Slot).Lifecycle := State;
            Records (Slot).Revision := Records (Slot).Revision + 1;
            if State in A11y.Nodes.Defunct | A11y.Nodes.Removed then
               Records (Slot).Tombstone := True;
               Records (Slot).Provider := null;
               Records (Slot).Parent := A11y.Node_Ids.No_Node;
            end if;
            Result := A11y.Results.Ok;
         end if;
      end Set_Lifecycle;

      procedure Set_Parent
        (Id     : A11y.Node_Ids.Node_Id;
         Parent : A11y.Node_Ids.Node_Id;
         Result : out A11y.Results.Result)
      is
         Slot : constant Natural := A11y.Node_Ids.To_Natural (Id);
         Parent_Slot : constant Natural := A11y.Node_Ids.To_Natural (Parent);
      begin
         if Slot = 0 or else Slot >= Next_Id or else not Records (Slot).Used
           or else Records (Slot).Tombstone
         then
            Result := (Status => A11y.Results.Node_Unavailable);
         elsif Parent /= A11y.Node_Ids.No_Node
           and then not A11y.Node_Ids.Is_Valid (Parent)
         then
            Result := (Status => A11y.Results.Node_Unavailable);
         elsif A11y.Node_Ids.Is_Valid (Parent)
           and then (Parent_Slot = 0
                     or else Parent_Slot >= Next_Id
                     or else not Records (Parent_Slot).Used
                     or else Records (Parent_Slot).Tombstone)
         then
            Result := (Status => A11y.Results.Node_Unavailable);
         elsif Parent = Id then
            Result := (Status => A11y.Results.Invalid_Argument);
         else
            Records (Slot).Parent := Parent;
            Records (Slot).Revision := Records (Slot).Revision + 1;
            Result := A11y.Results.Ok;
         end if;
      end Set_Parent;

      procedure Lookup
        (Id       : A11y.Node_Ids.Node_Id;
         Provider : out Node_Access;
         State    : out A11y.Nodes.Lifecycle_State;
         Result   : out A11y.Results.Result)
      is
         Slot : constant Natural := A11y.Node_Ids.To_Natural (Id);
      begin
         Provider := null;
         State := A11y.Nodes.Removed;
         if Slot = 0 or else Slot >= Next_Id or else not Records (Slot).Used
           or else Records (Slot).Tombstone
         then
            Result := (Status => A11y.Results.Node_Unavailable);
         else
            Provider := Records (Slot).Provider;
            State := Records (Slot).Lifecycle;
            Result := A11y.Results.Ok;
         end if;
      end Lookup;

      procedure Snapshot
        (Id     : A11y.Node_Ids.Node_Id;
         Item   : out Entry_Snapshot;
         Result : out A11y.Results.Result)
      is
         Slot : constant Natural := A11y.Node_Ids.To_Natural (Id);
      begin
         Item := (others => <>);
         if Slot = 0 or else Slot >= Next_Id or else not Records (Slot).Used then
            Result := (Status => A11y.Results.Node_Unavailable);
         else
            Item.Id := Id;
            Item.Lifecycle := Records (Slot).Lifecycle;
            Item.Parent := Records (Slot).Parent;
            Item.Revision := Records (Slot).Revision;
            Item.Capabilities := Records (Slot).Capabilities;
            Item.Pinned := Records (Slot).Pinned;
            Item.Pin_Limit := Pin_Limit;
            Item.Tombstone := Records (Slot).Tombstone;
            Result := A11y.Results.Ok;
         end if;
      end Snapshot;

      procedure Pin_Node
        (Id     : A11y.Node_Ids.Node_Id;
         Token  : out Pin;
         Result : out A11y.Results.Result)
      is
         Slot : constant Natural := A11y.Node_Ids.To_Natural (Id);
      begin
         Token := (Id => A11y.Node_Ids.No_Node, Active => False);
         if Slot = 0 or else Slot >= Next_Id or else not Records (Slot).Used
           or else Records (Slot).Tombstone
         then
            Result := (Status => A11y.Results.Node_Unavailable);
         elsif Records (Slot).Pinned >= Pin_Limit then
            Result := (Status => A11y.Results.Resource_Limit);
         else
            Records (Slot).Pinned := Records (Slot).Pinned + 1;
            Token := (Id => Id, Active => True);
            Result := A11y.Results.Ok;
         end if;
      end Pin_Node;

      procedure Unpin_Node (Token : in out Pin) is
         Slot : constant Natural := A11y.Node_Ids.To_Natural (Token.Id);
      begin
         if Token.Active and then Slot > 0 and then Slot < Next_Id
           and then Records (Slot).Used and then Records (Slot).Pinned > 0
         then
            Records (Slot).Pinned := Records (Slot).Pinned - 1;
         end if;
         Token := (Id => A11y.Node_Ids.No_Node, Active => False);
      end Unpin_Node;

      procedure Remove
        (Id     : A11y.Node_Ids.Node_Id;
         Result : out A11y.Results.Result)
      is
         Slot : constant Natural := A11y.Node_Ids.To_Natural (Id);
         Transition : A11y.Results.Result;
      begin
         if Slot = 0 or else Slot >= Next_Id or else not Records (Slot).Used then
            Result := (Status => A11y.Results.Node_Unavailable);
         else
            Transition := A11y.Nodes.Validate_Transition
              (Records (Slot).Lifecycle, A11y.Nodes.Removed);
            if A11y.Results.Failed (Transition) then
               Result := Transition;
               return;
            end if;

            Records (Slot).Lifecycle := A11y.Nodes.Removed;
            Records (Slot).Provider := null;
            Records (Slot).Parent := A11y.Node_Ids.No_Node;
            Records (Slot).Tombstone := True;
            Records (Slot).Revision := Records (Slot).Revision + 1;
            Result := A11y.Results.Ok;
         end if;
      end Remove;
   end Node_Registry;

end A11y.Registry;
