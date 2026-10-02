with A11y.Trees.Exposure_Views;

package body A11y.MacOS_Backend.NSAccessibility_Table is
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Nodes.Exposure_Policy;

   function Error (Status : A11y.Results.Status_Code) return Table_Reply is
     (Kind => Error_Reply, Status => Status);

   function Exposure_Of
     (Snapshot : Table_Snapshot;
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
     (Snapshot : Table_Snapshot;
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
      if not Snapshot.Use_Tree_Projection then
         return True;
      elsif not A11y.Node_Ids.Is_Valid (Snapshot.Root)
        or else not A11y.Node_Ids.Is_Valid (Node)
      then
         return False;
      elsif Node = Snapshot.Root then
         return Exposure_Of (Snapshot, Node) = A11y.Nodes.Expose_Node;
      end if;

      Parent := Exposure_View.Exposed_Parent_Of
        (Snapshot.Tree, Node, Limits, Result);
      return A11y.Results.Succeeded (Result)
        and then A11y.Node_Ids.Is_Valid (Parent);
   exception
      when others =>
         return False;
   end Is_Externally_Exposed;

   function Resolve_Exposed_Cell
     (Snapshot : Table_Snapshot;
      Row      : A11y.Tables.Logical_Index;
      Column   : A11y.Tables.Logical_Index;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
      return A11y.Tables.Cell_Reference
   is
      Cell : A11y.Tables.Cell_Reference;
   begin
      Cell := A11y.Tables.Resolve_Cell (Snapshot.Table, Row, Column, Result);
      if A11y.Results.Failed (Result) then
         return Cell;
      elsif not Is_Externally_Exposed (Snapshot, Cell.Node, Limits) then
         Result := (Status => A11y.Results.Node_Unavailable);
      end if;

      return Cell;
   end Resolve_Exposed_Cell;

   function Query_Table
     (Snapshot : Table_Snapshot;
      Query    : Table_Query;
      Row      : A11y.Tables.Logical_Index := 0;
      Column   : A11y.Tables.Logical_Index := 0)
      return Table_Reply is
     (Query_Table (Snapshot, Query, Snapshot.Limits, Row, Column));

   function Query_Table
     (Snapshot : Table_Snapshot;
      Query    : Table_Query;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Row      : A11y.Tables.Logical_Index := 0;
      Column   : A11y.Tables.Logical_Index := 0)
      return Table_Reply
   is
      Result : A11y.Results.Result;
      Cell   : A11y.Tables.Cell_Reference;
      Node   : A11y.Node_Ids.Node_Id;
      Sort   : A11y.Tables.Sort_State;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      elsif Snapshot.Defunct then
         return Error (A11y.Results.Node_Unavailable);
      elsif Snapshot.Use_Tree_Projection
        and then A11y.Node_Ids.Is_Valid (Snapshot.Id)
        and then not Is_Externally_Exposed (Snapshot, Snapshot.Id, Limits)
      then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      case Query is
         when Row_Count =>
            return
              (Kind   => UInt32_Reply,
               Status => A11y.Results.Success,
               UInt32 => Natural (A11y.Tables.Row_Count (Snapshot.Table)));
         when Column_Count =>
            return
              (Kind   => UInt32_Reply,
               Status => A11y.Results.Success,
               UInt32 => Natural (A11y.Tables.Column_Count (Snapshot.Table)));
         when Displayed_Row_Count =>
            return
              (Kind   => UInt32_Reply,
               Status => A11y.Results.Success,
               UInt32 =>
                 Natural (A11y.Tables.Displayed_Row_Count (Snapshot.Table)));
         when Displayed_Column_Count =>
            return
              (Kind   => UInt32_Reply,
               Status => A11y.Results.Success,
               UInt32 =>
                 Natural
                   (A11y.Tables.Displayed_Column_Count (Snapshot.Table)));
         when Visible_Row_Start =>
            return
              (Kind   => UInt32_Reply,
               Status => A11y.Results.Success,
               UInt32 => Natural (A11y.Tables.Visible_Rows (Snapshot.Table).First));
         when Visible_Row_Count =>
            return
              (Kind   => UInt32_Reply,
               Status => A11y.Results.Success,
               UInt32 => Natural (A11y.Tables.Visible_Rows (Snapshot.Table).Count));
         when Visible_Column_Start =>
            return
              (Kind   => UInt32_Reply,
               Status => A11y.Results.Success,
               UInt32 =>
                 Natural (A11y.Tables.Visible_Columns (Snapshot.Table).First));
         when Visible_Column_Count =>
            return
              (Kind   => UInt32_Reply,
               Status => A11y.Results.Success,
               UInt32 =>
                 Natural (A11y.Tables.Visible_Columns (Snapshot.Table).Count));
         when Current_Cell =>
            Node := A11y.Tables.Current_Cell (Snapshot.Table);
            if not A11y.Node_Ids.Is_Valid (Node) then
               return Error (A11y.Results.Node_Unavailable);
            elsif not Is_Externally_Exposed (Snapshot, Node, Limits) then
               return Error (A11y.Results.Node_Unavailable);
            end if;
            return
              (Kind   => Node_Reply,
               Status => A11y.Results.Success,
               Node   => Node);
         when Sort_Order =>
            Sort := A11y.Tables.Current_Sort (Snapshot.Table);
            return
              (Kind   => UInt32_Reply,
               Status => A11y.Results.Success,
               UInt32 => A11y.Tables.Sort_Order'Pos (Sort.Order));
         when Sort_Key =>
            Sort := A11y.Tables.Current_Sort (Snapshot.Table);
            Node := Sort.Key_Node;
            if not A11y.Node_Ids.Is_Valid (Node) then
               return Error (A11y.Results.Node_Unavailable);
            elsif not Is_Externally_Exposed (Snapshot, Node, Limits) then
               return Error (A11y.Results.Node_Unavailable);
            end if;
            return
              (Kind   => Node_Reply,
               Status => A11y.Results.Success,
               Node   => Node);
         when Cell_At =>
            Cell := Resolve_Exposed_Cell
              (Snapshot, Row, Column, Limits, Result);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;
            return
              (Kind   => Node_Reply,
               Status => A11y.Results.Success,
               Node   => Cell.Node);
         when Row_Span =>
            Cell := Resolve_Exposed_Cell
              (Snapshot, Row, Column, Limits, Result);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;
            return
              (Kind   => UInt32_Reply,
               Status => A11y.Results.Success,
               UInt32 => Cell.Row_Span);
         when Column_Span =>
            Cell := Resolve_Exposed_Cell
              (Snapshot, Row, Column, Limits, Result);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;
            return
              (Kind   => UInt32_Reply,
               Status => A11y.Results.Success,
               UInt32 => Cell.Column_Span);
      end case;
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Query_Table;

end A11y.MacOS_Backend.NSAccessibility_Table;
