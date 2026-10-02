package body A11y.Trees.Exposure_Views is
   use type A11y.Node_Ids.Node_Id;

   function Depth_Limit
     (Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return Natural is
     (Natural
        (A11y.Resource_Limits.Value
           (Limits, A11y.Resource_Limits.Traversal_Depth)));

   function Array_Limit
     (Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return Natural is
     (Natural
        (A11y.Resource_Limits.Value
           (Limits, A11y.Resource_Limits.Native_Array_Size)));

   function Policy
     (Node : A11y.Node_Ids.Node_Id)
      return A11y.Nodes.Exposure_Policy is
     (Exposure_Of (Node));

   procedure Append_Visible_Descendants
     (Self     : Semantic_Tree;
      Node     : A11y.Node_Ids.Node_Id;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Depth    : Natural;
      Children : in out Child_Vectors.Vector;
      Result   : in out A11y.Results.Result)
   is
      Node_Policy : A11y.Nodes.Exposure_Policy;
      Raw_Children : Child_Vectors.Vector;
   begin
      if A11y.Results.Failed (Result) then
         return;
      elsif Depth > Depth_Limit (Limits) then
         Result := (Status => A11y.Results.Resource_Limit);
         return;
      elsif not Is_Attached (Self, Node) then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      end if;

      Node_Policy := Policy (Node);
      if A11y.Nodes.Exposes_Node (Node_Policy) then
         if Natural (Children.Length) >= Array_Limit (Limits) then
            Result := (Status => A11y.Results.Resource_Limit);
            return;
         end if;

         Children.Append (Node);
      elsif A11y.Nodes.Exposes_Descendants (Node_Policy) then
         Raw_Children := Children_Of (Self, Node);
         for Child of Raw_Children loop
            Append_Visible_Descendants
              (Self, Child, Limits, Depth + 1, Children, Result);
            if A11y.Results.Failed (Result) then
               return;
            end if;
         end loop;
      end if;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Append_Visible_Descendants;

   procedure Exposed_Children_Of
     (Self     : Semantic_Tree;
      Node     : A11y.Node_Ids.Node_Id;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Children : out Child_Vectors.Vector;
      Result   : out A11y.Results.Result)
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      Node_Policy : A11y.Nodes.Exposure_Policy;
      Raw_Children : Child_Vectors.Vector;
   begin
      Children := Child_Vectors.Empty_Vector;
      if A11y.Results.Failed (Validation) then
         Result := Validation;
         return;
      elsif not Is_Attached (Self, Node) then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      end if;

      Node_Policy := Policy (Node);
      if not A11y.Nodes.Exposes_Descendants (Node_Policy) then
         Result := A11y.Results.Ok;
         return;
      end if;

      Raw_Children := Children_Of (Self, Node);
      for Child of Raw_Children loop
         Append_Visible_Descendants
           (Self, Child, Limits, 1, Children, Result);
         if A11y.Results.Failed (Result) then
            return;
         end if;
      end loop;

      Result := A11y.Results.Ok;
   exception
      when others =>
         Children := Child_Vectors.Empty_Vector;
         Result := (Status => A11y.Results.Internal_Error);
   end Exposed_Children_Of;

   procedure Exposed_Children_Of
     (Self     : Semantic_Tree;
      Node     : A11y.Node_Ids.Node_Id;
      Children : out Child_Vectors.Vector;
      Result   : out A11y.Results.Result)
   is
   begin
      Exposed_Children_Of
        (Self,
         Node,
         A11y.Resource_Limits.Default_Config,
         Children,
         Result);
   end Exposed_Children_Of;

   function Hidden_By_Ancestor
     (Self   : Semantic_Tree;
      Node   : A11y.Node_Ids.Node_Id;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return Boolean
   is
      Current : A11y.Node_Ids.Node_Id := Node;
      Depth : Natural := 0;
      Node_Policy : A11y.Nodes.Exposure_Policy;
   begin
      while A11y.Node_Ids.Is_Valid (Current) loop
         Depth := Depth + 1;
         if Depth > Depth_Limit (Limits) then
            return True;
         end if;

         Node_Policy := Policy (Current);
         if not A11y.Nodes.Exposes_Node (Node_Policy)
           and then not A11y.Nodes.Exposes_Descendants
             (Node_Policy)
         then
            return True;
         end if;

         Current := Parent_Of (Self, Current);
      end loop;

      return False;
   end Hidden_By_Ancestor;

   function Exposed_Parent_Of
     (Self   : Semantic_Tree;
      Node   : A11y.Node_Ids.Node_Id;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      Current : A11y.Node_Ids.Node_Id;
      Depth : Natural := 0;
   begin
      if A11y.Results.Failed (Validation) then
         Result := Validation;
         return A11y.Node_Ids.No_Node;
      elsif not Is_Attached (Self, Node)
        or else not A11y.Nodes.Exposes_Node (Policy (Node))
        or else Hidden_By_Ancestor (Self, Node, Limits)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return A11y.Node_Ids.No_Node;
      end if;

      Current := Parent_Of (Self, Node);
      while A11y.Node_Ids.Is_Valid (Current) loop
         Depth := Depth + 1;
         if Depth > Depth_Limit (Limits) then
            Result := (Status => A11y.Results.Resource_Limit);
            return A11y.Node_Ids.No_Node;
         elsif A11y.Nodes.Exposes_Node (Policy (Current)) then
            Result := A11y.Results.Ok;
            return Current;
         elsif not A11y.Nodes.Exposes_Descendants
           (Policy (Current))
         then
            Result := (Status => A11y.Results.Node_Unavailable);
            return A11y.Node_Ids.No_Node;
         end if;

         Current := Parent_Of (Self, Current);
      end loop;

      Result := A11y.Results.Ok;
      return A11y.Node_Ids.No_Node;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return A11y.Node_Ids.No_Node;
   end Exposed_Parent_Of;

   function Exposed_Parent_Of
     (Self   : Semantic_Tree;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id
   is
   begin
      return Exposed_Parent_Of
        (Self, Node, A11y.Resource_Limits.Default_Config, Result);
   end Exposed_Parent_Of;

   function Is_Externally_Exposed
     (Self   : Semantic_Tree;
      Node   : A11y.Node_Ids.Node_Id;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return Boolean
   is
      Result : A11y.Results.Result;
      Ignored : A11y.Node_Ids.Node_Id;
   begin
      if not Is_Attached (Self, Node)
        or else not A11y.Nodes.Exposes_Node (Policy (Node))
      then
         return False;
      end if;

      Ignored := Exposed_Parent_Of (Self, Node, Limits, Result);
      return A11y.Results.Succeeded (Result)
        and then (A11y.Node_Ids.Is_Valid (Ignored) or else Node = Root (Self));
   end Is_Externally_Exposed;

   function Is_Externally_Exposed
     (Self : Semantic_Tree;
      Node : A11y.Node_Ids.Node_Id)
      return Boolean is
     (Is_Externally_Exposed
        (Self, Node, A11y.Resource_Limits.Default_Config));

end A11y.Trees.Exposure_Views;
