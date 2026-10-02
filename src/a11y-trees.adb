with A11y.Trees.Classification;

package body A11y.Trees is
   use type A11y.Node_Ids.Node_Id;

   function Slot_Of (Node : A11y.Node_Ids.Node_Id) return Natural is
     (A11y.Node_Ids.To_Natural (Node));

   function In_Range (Node : A11y.Node_Ids.Node_Id) return Boolean is
     (Is_Addressable (Node));

   function Is_Addressable
     (Node : A11y.Node_Ids.Node_Id)
      return Boolean is
     (A11y.Trees.Classification.Is_Addressable (Node))
   with SPARK_Mode => On;

   function Valid_Attachment_Pair
     (Parent : A11y.Node_Ids.Node_Id;
      Child  : A11y.Node_Ids.Node_Id)
      return Boolean is
     (A11y.Trees.Classification.Valid_Attachment_Pair (Parent, Child))
   with SPARK_Mode => On;

   function Can_Detach_Node
     (Root_Node : A11y.Node_Ids.Node_Id;
      Node      : A11y.Node_Ids.Node_Id)
      return Boolean is
     (A11y.Trees.Classification.Can_Detach_Node (Root_Node, Node))
   with SPARK_Mode => On;

   function Can_Move_Node
     (Root_Node   : A11y.Node_Ids.Node_Id;
      New_Parent  : A11y.Node_Ids.Node_Id;
      Node        : A11y.Node_Ids.Node_Id)
      return Boolean is
     (A11y.Trees.Classification.Can_Move_Node
        (Root_Node, New_Parent, Node))
   with SPARK_Mode => On;

   function Root (Self : Semantic_Tree) return A11y.Node_Ids.Node_Id is
     (Self.Root_Node);

   function Is_Attached
     (Self : Semantic_Tree;
      Node : A11y.Node_Ids.Node_Id)
      return Boolean
   is
      Slot : constant Natural := Slot_Of (Node);
   begin
      return In_Range (Node) and then Self.Nodes (Slot).Attached;
   end Is_Attached;

   function Parent_Of
     (Self : Semantic_Tree;
      Node : A11y.Node_Ids.Node_Id)
      return A11y.Node_Ids.Node_Id
   is
      Slot : constant Natural := Slot_Of (Node);
   begin
      if not In_Range (Node) or else not Self.Nodes (Slot).Attached then
         return A11y.Node_Ids.No_Node;
      end if;
      return Self.Nodes (Slot).Parent;
   end Parent_Of;

   function Child_Count
     (Self : Semantic_Tree;
      Node : A11y.Node_Ids.Node_Id)
      return Natural
   is
      Slot : constant Natural := Slot_Of (Node);
   begin
      if not In_Range (Node) or else not Self.Nodes (Slot).Attached then
         return 0;
      end if;
      return Natural (Self.Nodes (Slot).Children.Length);
   end Child_Count;

   function Child_At
     (Self  : Semantic_Tree;
      Node  : A11y.Node_Ids.Node_Id;
      Index : Positive)
      return A11y.Node_Ids.Node_Id
   is
      Slot : constant Natural := Slot_Of (Node);
      Count : Natural := 0;
   begin
      if In_Range (Node) then
         Count := Natural (Self.Nodes (Slot).Children.Length);
      end if;

      if not In_Range (Node)
        or else not Self.Nodes (Slot).Attached
        or else Index > Count
      then
         return A11y.Node_Ids.No_Node;
      end if;
      return Self.Nodes (Slot).Children (Index);
   end Child_At;

   function Children_Of
     (Self : Semantic_Tree;
      Node : A11y.Node_Ids.Node_Id)
      return Child_Vectors.Vector
   is
      Slot : constant Natural := Slot_Of (Node);
   begin
      if not In_Range (Node) or else not Self.Nodes (Slot).Attached then
         return Child_Vectors.Empty_Vector;
      end if;
      return Self.Nodes (Slot).Children;
   end Children_Of;

   function Is_Descendant
     (Self     : Semantic_Tree;
      Ancestor : A11y.Node_Ids.Node_Id;
      Node     : A11y.Node_Ids.Node_Id)
      return Boolean
   is
      Current : A11y.Node_Ids.Node_Id := Node;
   begin
      while A11y.Node_Ids.Is_Valid (Current) loop
         if Current = Ancestor then
            return True;
         end if;
         Current := Parent_Of (Self, Current);
      end loop;
      return False;
   end Is_Descendant;

   function Child_Index
     (Self   : Semantic_Tree;
      Parent : A11y.Node_Ids.Node_Id;
      Child  : A11y.Node_Ids.Node_Id)
      return Natural
   is
      Parent_Slot : constant Natural := Slot_Of (Parent);
   begin
      if not In_Range (Parent) or else not Self.Nodes (Parent_Slot).Attached then
         return 0;
      end if;

      if Self.Nodes (Parent_Slot).Children.Is_Empty then
         return 0;
      end if;

      for Index in
        Self.Nodes (Parent_Slot).Children.First_Index ..
        Self.Nodes (Parent_Slot).Children.Last_Index
      loop
         if Self.Nodes (Parent_Slot).Children (Index) = Child then
            return Index;
         end if;
      end loop;

      return 0;
   end Child_Index;

   procedure Set_Root
     (Self   : in out Semantic_Tree;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
   is
      Slot : constant Natural := Slot_Of (Node);
   begin
      if not In_Range (Node) then
         Result := (Status => A11y.Results.Invalid_Argument);
      elsif A11y.Node_Ids.Is_Valid (Self.Root_Node) then
         Result := (Status => A11y.Results.Invalid_State);
      else
         Self.Root_Node := Node;
         Self.Nodes (Slot).Attached := True;
         Self.Nodes (Slot).Parent := A11y.Node_Ids.No_Node;
         Result := A11y.Results.Ok;
      end if;
   end Set_Root;

   procedure Attach
     (Self   : in out Semantic_Tree;
      Parent : A11y.Node_Ids.Node_Id;
      Child  : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
   is
      Parent_Slot : constant Natural := Slot_Of (Parent);
      Child_Slot  : constant Natural := Slot_Of (Child);
   begin
      if not Valid_Attachment_Pair (Parent, Child) then
         Result := (Status => A11y.Results.Invalid_Argument);
      elsif not Self.Nodes (Parent_Slot).Attached then
         Result := (Status => A11y.Results.Node_Unavailable);
      elsif Self.Nodes (Child_Slot).Attached then
         Result := (Status => A11y.Results.Invalid_State);
      else
         Self.Nodes (Child_Slot).Attached := True;
         Self.Nodes (Child_Slot).Parent := Parent;
         Self.Nodes (Parent_Slot).Children.Append (Child);
         Result := A11y.Results.Ok;
      end if;
   end Attach;

   procedure Detach
     (Self   : in out Semantic_Tree;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
   is
      Slot : constant Natural := Slot_Of (Node);
      Parent : A11y.Node_Ids.Node_Id;
      Parent_Slot : Natural;
      Index : Natural;
   begin
      if not In_Range (Node) or else not Self.Nodes (Slot).Attached then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      end if;

      if not Can_Detach_Node (Self.Root_Node, Node) then
         Result := (Status => A11y.Results.Invalid_State);
         return;
      elsif not Self.Nodes (Slot).Children.Is_Empty then
         Result := (Status => A11y.Results.Invalid_State);
         return;
      end if;

      Parent := Self.Nodes (Slot).Parent;
      Parent_Slot := Slot_Of (Parent);
      Index := Child_Index (Self, Parent, Node);
      if Index /= 0 then
         Self.Nodes (Parent_Slot).Children.Delete (Index);
      end if;

      Self.Nodes (Slot).Attached := False;
      Self.Nodes (Slot).Parent := A11y.Node_Ids.No_Node;
      Self.Nodes (Slot).Children.Clear;
      Result := A11y.Results.Ok;
   end Detach;

   procedure Detach_Subtree
     (Self   : in out Semantic_Tree;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
   is
      Slot : constant Natural := Slot_Of (Node);
      Parent : A11y.Node_Ids.Node_Id;
      Parent_Slot : Natural;
      Index : Natural;

      procedure Clear_Subtree (Current : A11y.Node_Ids.Node_Id) is
         Current_Slot : constant Natural := Slot_Of (Current);
         Children : Child_Vectors.Vector;
      begin
         if not In_Range (Current)
           or else not Self.Nodes (Current_Slot).Attached
         then
            return;
         end if;

         Children := Self.Nodes (Current_Slot).Children;
         for Child of Children loop
            Clear_Subtree (Child);
         end loop;

         Self.Nodes (Current_Slot).Attached := False;
         Self.Nodes (Current_Slot).Parent := A11y.Node_Ids.No_Node;
         Self.Nodes (Current_Slot).Children.Clear;
      end Clear_Subtree;
   begin
      if not In_Range (Node) or else not Self.Nodes (Slot).Attached then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      end if;

      if Node = Self.Root_Node then
         Self.Root_Node := A11y.Node_Ids.No_Node;
      else
         Parent := Self.Nodes (Slot).Parent;
         Parent_Slot := Slot_Of (Parent);
         Index := Child_Index (Self, Parent, Node);
         if Index /= 0 then
            Self.Nodes (Parent_Slot).Children.Delete (Index);
         end if;
      end if;

      Clear_Subtree (Node);
      Result := A11y.Results.Ok;
   end Detach_Subtree;

   procedure Move
     (Self       : in out Semantic_Tree;
      New_Parent : A11y.Node_Ids.Node_Id;
      Node       : A11y.Node_Ids.Node_Id;
      Result     : out A11y.Results.Result)
   is
      Node_Slot : constant Natural := Slot_Of (Node);
      Old_Parent : A11y.Node_Ids.Node_Id;
      Old_Parent_Slot : Natural;
      New_Parent_Slot : constant Natural := Slot_Of (New_Parent);
      Index : Natural;
   begin
      if not Valid_Attachment_Pair (New_Parent, Node) then
         Result := (Status => A11y.Results.Invalid_Argument);
      elsif not Can_Move_Node (Self.Root_Node, New_Parent, Node)
        or else not Self.Nodes (Node_Slot).Attached
        or else not Self.Nodes (New_Parent_Slot).Attached
      then
         Result := (Status => A11y.Results.Node_Unavailable);
      elsif Is_Descendant (Self, Node, New_Parent) then
         Result := (Status => A11y.Results.Invalid_State);
      else
         Old_Parent := Self.Nodes (Node_Slot).Parent;
         Old_Parent_Slot := Slot_Of (Old_Parent);
         Index := Child_Index (Self, Old_Parent, Node);
         if Index /= 0 then
            Self.Nodes (Old_Parent_Slot).Children.Delete (Index);
         end if;
         Self.Nodes (Node_Slot).Parent := New_Parent;
         Self.Nodes (New_Parent_Slot).Children.Append (Node);
         Result := A11y.Results.Ok;
      end if;
   end Move;

   function Validate
     (Self   : Semantic_Tree;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return A11y.Results.Result
   is
      Root_Count : Natural := 0;
      Result     : A11y.Results.Result;
      Depth_Limit : Natural;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;
      Depth_Limit := Natural
        (A11y.Resource_Limits.Value
           (Limits, A11y.Resource_Limits.Traversal_Depth));

      if not A11y.Node_Ids.Is_Valid (Self.Root_Node) then
         return (Status => A11y.Results.Invalid_State);
      end if;

      for Slot in Self.Nodes'Range loop
         if Self.Nodes (Slot).Attached then
            declare
               Current : A11y.Node_Ids.Node_Id :=
                 A11y.Node_Ids.From_Natural (Slot);
               Depth : Natural := 1;
            begin
               while A11y.Node_Ids.Is_Valid (Parent_Of (Self, Current)) loop
                  Depth := Depth + 1;
                  if Depth > Depth_Limit then
                     return (Status => A11y.Results.Resource_Limit);
                  elsif Depth > Max_Attached_Nodes then
                     return (Status => A11y.Results.Invalid_State);
                  end if;
                  Current := Parent_Of (Self, Current);
               end loop;
            end;

            if Self.Nodes (Slot).Parent = A11y.Node_Ids.No_Node then
               Root_Count := Root_Count + 1;
            elsif not Is_Attached (Self, Self.Nodes (Slot).Parent) then
               return (Status => A11y.Results.Node_Unavailable);
            end if;

            if not Self.Nodes (Slot).Children.Is_Empty then
               for Child_Index in
                 Self.Nodes (Slot).Children.First_Index ..
                 Self.Nodes (Slot).Children.Last_Index
               loop
                  declare
                     Child : constant A11y.Node_Ids.Node_Id :=
                       Self.Nodes (Slot).Children (Child_Index);
                  begin
                     if not Is_Attached (Self, Child)
                       or else Parent_Of (Self, Child) /=
                         A11y.Node_Ids.From_Natural (Slot)
                     then
                        return (Status => A11y.Results.Invalid_State);
                     end if;

                     if Child_Index < Self.Nodes (Slot).Children.Last_Index then
                        for Other_Index in
                          Child_Index + 1 ..
                          Self.Nodes (Slot).Children.Last_Index
                        loop
                           if Self.Nodes (Slot).Children (Other_Index) = Child then
                              return (Status => A11y.Results.Invalid_State);
                           end if;
                        end loop;
                     end if;
                  end;
               end loop;
            end if;
         end if;
      end loop;

      if Root_Count /= 1 then
         return (Status => A11y.Results.Invalid_State);
      end if;

      return A11y.Results.Ok;
   end Validate;

   function Validate (Self : Semantic_Tree) return A11y.Results.Result is
     (Validate (Self, A11y.Resource_Limits.Default_Config));

end A11y.Trees;
