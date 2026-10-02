with A11y.Trees.Exposure_Views;

package body A11y.MacOS_Backend.NSAccessibility_Selection is
   use type A11y.Selection.Selection_Mode;
   use type A11y.Node_Ids.Node_Id;

   function Error (Status : A11y.Results.Status_Code) return Selection_Reply is
     (Kind   => Error_Reply,
      Status => Status);

   function Node_Or_Nil
     (Node : A11y.Node_Ids.Node_Id)
      return Selection_Reply is
   begin
      if A11y.Node_Ids.Is_Valid (Node) then
         return
           (Kind   => Node_Reply,
            Status => A11y.Results.Success,
            Node   => Node,
            Request => Select_Item);
      end if;

      return
        (Kind   => Nil_Reply,
         Status => A11y.Results.Success);
   end Node_Or_Nil;

   function Exposure_Of
     (Snapshot : Selection_Snapshot;
      Node     : A11y.Node_Ids.Node_Id)
      return A11y.Nodes.Exposure_Policy
   is
      Slot : constant Natural := A11y.Node_Ids.To_Natural (Node);
   begin
      if Slot not in Snapshot.Exposure'Range then
         return A11y.Nodes.Hide_Node_And_Subtree;
      end if;

      return Snapshot.Exposure (Slot);
   end Exposure_Of;

   function Is_Externally_Exposed
     (Snapshot : Selection_Snapshot;
      Node     : A11y.Node_Ids.Node_Id;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Boolean
   is
      function Policy_For
        (Current : A11y.Node_Ids.Node_Id)
         return A11y.Nodes.Exposure_Policy is
        (Exposure_Of (Snapshot, Current));

      package Exposure_View is new A11y.Trees.Exposure_Views
        (Exposure_Of => Policy_For);

      Parent : A11y.Node_Ids.Node_Id;
      Query_Result : A11y.Results.Result;
   begin
      Parent := Exposure_View.Exposed_Parent_Of
        (Snapshot.Tree, Node, Limits, Query_Result);
      return A11y.Results.Succeeded (Query_Result)
        and then
          (A11y.Node_Ids.Is_Valid (Parent)
           or else Node = Snapshot.Root);
   exception
      when others =>
         return False;
   end Is_Externally_Exposed;

   function Exposed_Selected_Count
     (Snapshot : Selection_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Natural
   is
      Count : Natural := 0;
   begin
      if not Snapshot.Use_Tree_Projection then
         return A11y.Selection.Count (Snapshot.Selection);
      end if;

      for Item of A11y.Selection.Items (Snapshot.Selection) loop
         if Is_Externally_Exposed (Snapshot, Item, Limits) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Exposed_Selected_Count;

   function Exposed_Selected_At
     (Snapshot : Selection_Snapshot;
      Index    : Positive;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return A11y.Node_Ids.Node_Id
   is
      Current : Positive := 1;
   begin
      if not Snapshot.Use_Tree_Projection then
         return A11y.Selection.Selected_At (Snapshot.Selection, Index);
      end if;

      for Item of A11y.Selection.Items (Snapshot.Selection) loop
         if Is_Externally_Exposed (Snapshot, Item, Limits) then
            if Current = Index then
               return Item;
            end if;
            Current := Current + 1;
         end if;
      end loop;

      return A11y.Node_Ids.No_Node;
   end Exposed_Selected_At;

   function Exposed_Node_Or_Nil
     (Snapshot : Selection_Snapshot;
      Node     : A11y.Node_Ids.Node_Id;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Selection_Reply is
   begin
      if Snapshot.Use_Tree_Projection
        and then A11y.Node_Ids.Is_Valid (Node)
        and then not Is_Externally_Exposed (Snapshot, Node, Limits)
      then
         return
           (Kind   => Nil_Reply,
            Status => A11y.Results.Success);
      end if;

      return Node_Or_Nil (Node);
   end Exposed_Node_Or_Nil;

   procedure Exposed_Select_All_Items
     (Snapshot : Selection_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Items    : out A11y.Selection.Node_Vectors.Vector;
      Result   : out A11y.Results.Result)
   is
   begin
      Items := A11y.Selection.Node_Vectors.Empty_Vector;
      for Item of Snapshot.Items loop
         if not A11y.Node_Ids.Is_Valid (Item) then
            Result := (Status => A11y.Results.Node_Unavailable);
            return;
         elsif not Snapshot.Use_Tree_Projection
           or else Is_Externally_Exposed (Snapshot, Item, Limits)
         then
            Items.Append (Item);
         end if;
      end loop;

      Result := A11y.Results.Ok;
   exception
      when others =>
         Items := A11y.Selection.Node_Vectors.Empty_Vector;
         Result := (Status => A11y.Results.Internal_Error);
   end Exposed_Select_All_Items;

   function Query_Selection
     (Snapshot : Selection_Snapshot;
      Query    : Selection_Query;
      Index    : Positive := 1)
      return Selection_Reply is
     (Query_Selection (Snapshot, Query, Snapshot.Limits, Index));

   function Query_Selection
     (Snapshot : Selection_Snapshot;
      Query    : Selection_Query;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Index    : Positive := 1)
      return Selection_Reply is
      Result : A11y.Results.Result;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      elsif Snapshot.Defunct then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      Result := A11y.Selection.Validate (Snapshot.Selection);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      if Snapshot.Use_Tree_Projection
        and then
          (not A11y.Node_Ids.Is_Valid (Snapshot.Root)
           or else not Is_Externally_Exposed (Snapshot, Snapshot.Root, Limits))
      then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      case Query is
         when Selected_Count =>
            return
              (Kind   => UInt32_Reply,
               Status => A11y.Results.Success,
               UInt32 => Exposed_Selected_Count (Snapshot, Limits));
         when Selected_Item =>
            declare
               Node : constant A11y.Node_Ids.Node_Id :=
                 Exposed_Selected_At (Snapshot, Index, Limits);
            begin
               if not A11y.Node_Ids.Is_Valid (Node) then
                  return Error (A11y.Results.Invalid_Argument);
               end if;

               return
                 (Kind   => Node_Reply,
                  Status => A11y.Results.Success,
                  Node   => Node,
                  Request => Select_Item);
            end;
         when Is_Item_Selected =>
            if not A11y.Node_Ids.Is_Valid (Snapshot.Item) then
               return Error (A11y.Results.Node_Unavailable);
            elsif Snapshot.Use_Tree_Projection
              and then not Is_Externally_Exposed
                (Snapshot, Snapshot.Item, Limits)
            then
               return
                 (Kind         => Boolean_Reply,
                  Status       => A11y.Results.Success,
                  Boolean_Item => False);
            end if;

            return
              (Kind         => Boolean_Reply,
               Status       => A11y.Results.Success,
               Boolean_Item =>
                 A11y.Selection.Contains (Snapshot.Selection, Snapshot.Item));
         when Is_Selection_Required =>
            return
              (Kind         => Boolean_Reply,
               Status       => A11y.Results.Success,
               Boolean_Item =>
                 A11y.Selection.Requires_Selection (Snapshot.Selection));
         when Allows_Multiple_Selection =>
            return
              (Kind         => Boolean_Reply,
               Status       => A11y.Results.Success,
               Boolean_Item =>
                 A11y.Selection.Mode (Snapshot.Selection)
                   in A11y.Selection.Multiple
                    | A11y.Selection.Contiguous_Multiple
                    | A11y.Selection.Extended);
         when Current_Item =>
            return Exposed_Node_Or_Nil
              (Snapshot,
               A11y.Selection.Current_Item (Snapshot.Selection),
               Limits);
         when Anchor_Item =>
            return Exposed_Node_Or_Nil
              (Snapshot, A11y.Selection.Anchor (Snapshot.Selection), Limits);
         when Selection_Direction =>
            return
              (Kind      => Direction_Reply,
               Status    => A11y.Results.Success,
               Direction => A11y.Selection.Direction (Snapshot.Selection));
      end case;
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Query_Selection;

   function Request_Selection
     (Snapshot : Selection_Snapshot;
      Request  : Selection_Request_Kind;
      Target   : A11y.Node_Ids.Node_Id;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Selection_Reply
   is
      Result : A11y.Results.Result;
      Candidate : A11y.Selection.Selection_Set := Snapshot.Selection;
      Selectable : A11y.Selection.Node_Vectors.Vector;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      elsif Snapshot.Defunct then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      Result := A11y.Selection.Validate (Snapshot.Selection);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      if Snapshot.Use_Tree_Projection
        and then
          (not A11y.Node_Ids.Is_Valid (Snapshot.Root)
           or else not Is_Externally_Exposed (Snapshot, Snapshot.Root, Limits))
      then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      if Request not in Select_All | Clear_Selection then
         if not A11y.Node_Ids.Is_Valid (Target) then
            return Error (A11y.Results.Node_Unavailable);
         elsif Snapshot.Use_Tree_Projection
           and then not Is_Externally_Exposed (Snapshot, Target, Limits)
         then
            return Error (A11y.Results.Node_Unavailable);
         end if;
      end if;

      case Request is
         when Select_Item =>
            A11y.Selection.Select_Item (Candidate, Target, Result);
         when Deselect_Item =>
            A11y.Selection.Deselect (Candidate, Target, Result);
         when Toggle_Item =>
            A11y.Selection.Toggle (Candidate, Target, Result);
         when Select_All =>
            Exposed_Select_All_Items
              (Snapshot, Limits, Selectable, Result);
            if A11y.Results.Succeeded (Result) then
               A11y.Selection.Select_All (Candidate, Selectable, Result);
            end if;
         when Clear_Selection =>
            A11y.Selection.Clear (Candidate, Result);
      end case;

      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      return
        (Kind   => Selection_Request_Reply,
         Status => A11y.Results.Success,
         Node   =>
           (if Request in Select_All | Clear_Selection
            then A11y.Node_Ids.No_Node
            else Target),
         Request => Request);
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Request_Selection;

   function Request_Selection
     (Snapshot : Selection_Snapshot;
      Request  : Selection_Request_Kind;
      Target   : A11y.Node_Ids.Node_Id)
      return Selection_Reply is
     (Request_Selection (Snapshot, Request, Target, Snapshot.Limits));

end A11y.MacOS_Backend.NSAccessibility_Selection;
