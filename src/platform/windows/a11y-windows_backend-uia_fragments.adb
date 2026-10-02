with A11y.Trees.Exposure_Views;

package body A11y.Windows_Backend.UIA_Fragments is
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Nodes.Exposure_Policy;

   function Error (Status : A11y.Results.Status_Code) return Fragment_Reply is
     (Found  => False,
      Status => Status);

   function Empty return Fragment_Reply is
     (Found  => False,
      Status => A11y.Results.Success);

   function Found (Node : A11y.Node_Ids.Node_Id) return Fragment_Reply is
     (Found  => True,
      Status => A11y.Results.Success,
      Node   => Node);

   function Validate
     (Snapshot : Fragment_Snapshot)
      return A11y.Results.Result is
   begin
      if Snapshot.Defunct
        or else not A11y.Native_Identity.Is_Valid (Snapshot.Session)
        or else not A11y.Node_Ids.Is_Valid (Snapshot.Fragment_Root)
        or else not A11y.Node_Ids.Is_Valid (Snapshot.Node)
        or else not A11y.Trees.Is_Attached (Snapshot.Tree, Snapshot.Fragment_Root)
        or else not A11y.Trees.Is_Attached (Snapshot.Tree, Snapshot.Node)
      then
         return (Status => A11y.Results.Node_Unavailable);
      end if;

      return A11y.Results.Ok;
   end Validate;

   function Exposure_Of
     (Snapshot : Fragment_Snapshot;
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

   function Bounds_Of
     (Snapshot : Fragment_Snapshot;
      Node     : A11y.Node_Ids.Node_Id)
      return A11y.Geometry.Rectangle
   is
      Slot : constant Natural := A11y.Node_Ids.To_Natural (Node);
   begin
      if Slot not in Snapshot.Bounds'Range then
         return A11y.Geometry.Empty_Rectangle;
      end if;

      return Snapshot.Bounds (Slot);
   end Bounds_Of;

   function Is_Externally_Exposed
     (Snapshot : Fragment_Snapshot;
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
      Result : A11y.Results.Result;
   begin
      if not A11y.Node_Ids.Is_Valid (Node)
        or else not A11y.Node_Ids.Is_Valid (Snapshot.Fragment_Root)
      then
         return False;
      elsif Exposure_Of (Snapshot, Node) /= A11y.Nodes.Expose_Node then
         return False;
      elsif Node = Snapshot.Fragment_Root then
         return True;
      end if;

      Parent := Exposure_View.Exposed_Parent_Of
        (Snapshot.Tree, Node, Limits, Result);
      return A11y.Results.Succeeded (Result)
        and then A11y.Node_Ids.Is_Valid (Parent);
   exception
      when others =>
         return False;
   end Is_Externally_Exposed;

   function Navigate
     (Snapshot  : Fragment_Snapshot;
      Direction : Navigate_Direction)
      return Fragment_Reply is
     (Navigate
        (Snapshot,
         Direction,
         A11y.Resource_Limits.Default_Config));

   function Navigate
     (Snapshot  : Fragment_Snapshot;
      Direction : Navigate_Direction;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config)
      return Fragment_Reply
   is
      Result : A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      Parent_Node : A11y.Node_Ids.Node_Id;
      Children : A11y.Trees.Child_Vectors.Vector;

      function Policy_For
        (Node : A11y.Node_Ids.Node_Id)
         return A11y.Nodes.Exposure_Policy is
        (Exposure_Of (Snapshot, Node));

      package Exposure_View is new A11y.Trees.Exposure_Views
        (Exposure_Of => Policy_For);

      function Externally_Exposed
        (Node : A11y.Node_Ids.Node_Id)
         return Boolean
      is
         Parent : A11y.Node_Ids.Node_Id;
         Query_Result : A11y.Results.Result;
      begin
         Parent := Exposure_View.Exposed_Parent_Of
           (Snapshot.Tree, Node, Limits, Query_Result);
         return A11y.Results.Succeeded (Query_Result)
           and then
             (A11y.Node_Ids.Is_Valid (Parent)
              or else Node = Snapshot.Fragment_Root);
      end Externally_Exposed;
   begin
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      Result := Validate (Snapshot);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      elsif not Externally_Exposed (Snapshot.Node) then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      case Direction is
         when Parent =>
            if Snapshot.Node = Snapshot.Fragment_Root then
               return Empty;
            end if;

            Parent_Node := Exposure_View.Exposed_Parent_Of
              (Snapshot.Tree, Snapshot.Node, Limits, Result);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            elsif A11y.Node_Ids.Is_Valid (Parent_Node) then
               return Found (Parent_Node);
            end if;

            return Empty;

         when First_Child =>
            Exposure_View.Exposed_Children_Of
              (Snapshot.Tree, Snapshot.Node, Limits, Children, Result);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            elsif Children.Is_Empty then
               return Empty;
            end if;

            return Found (Children (Children.First_Index));

         when Last_Child =>
            Exposure_View.Exposed_Children_Of
              (Snapshot.Tree, Snapshot.Node, Limits, Children, Result);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            elsif Children.Is_Empty then
               return Empty;
            end if;

            return Found (Children (Children.Last_Index));

         when Next_Sibling | Previous_Sibling =>
            if Snapshot.Node = Snapshot.Fragment_Root then
               return Empty;
            end if;

            Parent_Node := Exposure_View.Exposed_Parent_Of
              (Snapshot.Tree, Snapshot.Node, Limits, Result);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;

            if not A11y.Node_Ids.Is_Valid (Parent_Node) then
               return Empty;
            end if;

            Exposure_View.Exposed_Children_Of
              (Snapshot.Tree, Parent_Node, Limits, Children, Result);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;

            if Children.Is_Empty then
               return Error (A11y.Results.Invalid_State);
            end if;

            for Index in Children.First_Index .. Children.Last_Index loop
               if Children (Index) = Snapshot.Node then
                  if Direction = Next_Sibling
                    and then Index < Children.Last_Index
                  then
                     return Found (Children (Index + 1));
                  elsif Direction = Previous_Sibling
                    and then Index > Children.First_Index
                  then
                     return Found (Children (Index - 1));
                  end if;

                  return Empty;
               end if;
            end loop;

            return Error (A11y.Results.Invalid_State);
      end case;
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Navigate;

   function Fragment_Root
     (Snapshot : Fragment_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Fragment_Reply
   is
      Result : A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
   begin
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      Result := Validate (Snapshot);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      elsif not Is_Externally_Exposed
        (Snapshot, Snapshot.Fragment_Root, Limits)
      then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      return Found (Snapshot.Fragment_Root);
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Fragment_Root;

   function Focused_Node
     (Snapshot : Fragment_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Fragment_Reply
   is
      Result : A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
   begin
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      Result := Validate (Snapshot);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      elsif not Is_Externally_Exposed
        (Snapshot, Snapshot.Fragment_Root, Limits)
      then
         return Error (A11y.Results.Node_Unavailable);
      elsif not A11y.Node_Ids.Is_Valid (Snapshot.Focused_Node) then
         return Empty;
      elsif not A11y.Trees.Is_Attached (Snapshot.Tree, Snapshot.Focused_Node) then
         return Error (A11y.Results.Node_Unavailable);
      elsif not Is_Externally_Exposed
        (Snapshot, Snapshot.Focused_Node, Limits)
      then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      return Found (Snapshot.Focused_Node);
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Focused_Node;

   function Node_From_Point
     (Snapshot : Fragment_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Fragment_Reply
   is
      Result : A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      Depth_Limit : Natural := 0;

      function Search
        (Current : A11y.Node_Ids.Node_Id;
         Depth   : Natural)
         return A11y.Node_Ids.Node_Id
      is
         Children : A11y.Trees.Child_Vectors.Vector;
         Candidate : A11y.Node_Ids.Node_Id;
      begin
         if Depth > Depth_Limit
           or else not Is_Externally_Exposed (Snapshot, Current, Limits)
           or else not A11y.Geometry.Contains
             (Bounds_Of (Snapshot, Current), Snapshot.Hit_Test_Point)
         then
            return A11y.Node_Ids.No_Node;
         end if;

         Children := A11y.Trees.Children_Of (Snapshot.Tree, Current);
         if not Children.Is_Empty then
            for Index in reverse Children.First_Index .. Children.Last_Index loop
               Candidate := Search (Children (Index), Depth + 1);
               if A11y.Node_Ids.Is_Valid (Candidate) then
                  return Candidate;
               end if;
            end loop;
         end if;

         return Current;
      exception
         when others =>
            return A11y.Node_Ids.No_Node;
      end Search;

      Hit : A11y.Node_Ids.Node_Id;
   begin
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      Result := Validate (Snapshot);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      elsif not Is_Externally_Exposed
        (Snapshot, Snapshot.Fragment_Root, Limits)
      then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      Depth_Limit := Natural
        (A11y.Resource_Limits.Value
           (Limits, A11y.Resource_Limits.Traversal_Depth));
      Hit := Search (Snapshot.Fragment_Root, 0);
      if A11y.Node_Ids.Is_Valid (Hit) then
         return Found (Hit);
      end if;

      return Empty;
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Node_From_Point;

   function Build_Runtime_Id
     (Snapshot : Fragment_Snapshot)
      return Runtime_Id_Reply is
     (Build_Runtime_Id (Snapshot, A11y.Resource_Limits.Default_Config));

   function Build_Runtime_Id
     (Snapshot : Fragment_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Runtime_Id_Reply
   is
      Result : A11y.Results.Result;
      Root_Component : Natural;
      Node_Component : Natural;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return
           (Available => False,
            Status    => Result.Status);
      end if;

      Result := Validate (Snapshot);
      if A11y.Results.Failed (Result) then
         return
           (Available => False,
            Status    => Result.Status);
      elsif not Is_Externally_Exposed (Snapshot, Snapshot.Node, Limits) then
         return
           (Available => False,
            Status    => A11y.Results.Node_Unavailable);
      end if;

      Root_Component := A11y.Native_Identity.Runtime_Identifier_Component
        (Snapshot.Session, Snapshot.Fragment_Root, Result);
      if A11y.Results.Failed (Result) then
         return
           (Available => False,
            Status    => Result.Status);
      end if;

      Node_Component := A11y.Native_Identity.Runtime_Identifier_Component
        (Snapshot.Session, Snapshot.Node, Result);
      if A11y.Results.Failed (Result) then
         return
           (Available => False,
            Status    => Result.Status);
      end if;

      return
        (Available => True,
         Status    => A11y.Results.Success,
         Id        =>
           (Session_Component => A11y.Native_Identity.To_Natural
              (Snapshot.Session),
            Root_Component    => Root_Component,
            Node_Component    => Node_Component));
   exception
      when others =>
         return
           (Available => False,
            Status    => A11y.Results.Internal_Error);
   end Build_Runtime_Id;

end A11y.Windows_Backend.UIA_Fragments;
