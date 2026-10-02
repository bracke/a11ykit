with A11y.Linux.ATSPi_Objects;
with A11y.Linux.DBus_Codec;
with A11y.Trees.Exposure_Views;

package body A11y.Linux.ATSPi_Table is
   use Ada.Strings.Unbounded;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Nodes.Exposure_Policy;

   function Error (Status : A11y.Results.Status_Code) return Table_Reply is
     (Kind       => Error_Reply,
      Status     => Status,
      Error_Name => To_Unbounded_String
        (A11y.Linux.ATSPi_Objects.Error_Name (Status)));

   function Exposure_Of
     (Snapshot : Table_Method_Snapshot;
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
     (Snapshot : Table_Method_Snapshot;
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
     (Snapshot : Table_Method_Snapshot;
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

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Row      : A11y.Tables.Logical_Index;
      Column   : A11y.Tables.Logical_Index;
      Snapshot : Table_Method_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Table_Reply
   is
      Result : A11y.Results.Result;
      Node : A11y.Node_Ids.Node_Id;
      Encoded : A11y.Linux.DBus_Codec.DBus_Value;
      Cell : A11y.Tables.Cell_Reference;
      Sort : A11y.Tables.Sort_State;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      Node := A11y.Linux.ATSPi_Objects.Node_From_Object_Path
        (Path, Session, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      elsif Node /= Snapshot.Id or else Snapshot.Defunct then
         return Error (A11y.Results.Node_Unavailable);
      elsif not Is_Externally_Exposed (Snapshot, Snapshot.Id, Limits) then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      if Method = "GetNRows" then
         Encoded := A11y.Linux.DBus_Codec.Make_UInt32
           (Natural (A11y.Tables.Row_Count (Snapshot.Table)), Result);
      elsif Method = "GetNColumns" then
         Encoded := A11y.Linux.DBus_Codec.Make_UInt32
           (Natural (A11y.Tables.Column_Count (Snapshot.Table)), Result);
      else
         Encoded := (Kind => A11y.Linux.DBus_Codec.UInt32_Value, UInt32_Item => 0);
      end if;

      if Method = "GetNRows" or else Method = "GetNColumns" then
         if A11y.Results.Failed (Result) then
            return Error (Result.Status);
         end if;
         return
           (Kind   => UInt32_Reply,
            Status => A11y.Results.Success,
            UInt32 => Encoded.UInt32_Item);
      elsif Method = "GetAccessibleAt" then
         Cell := Resolve_Exposed_Cell (Snapshot, Row, Column, Limits, Result);
         if A11y.Results.Failed (Result) then
            return Error (Result.Status);
         end if;
         return
           (Kind   => Node_Reply,
            Status => A11y.Results.Success,
            Node   => Cell.Node);
      elsif Method = "GetRowExtentAt" then
         Cell := Resolve_Exposed_Cell (Snapshot, Row, Column, Limits, Result);
         if A11y.Results.Failed (Result) then
            return Error (Result.Status);
         end if;
         return
           (Kind   => UInt32_Reply,
            Status => A11y.Results.Success,
            UInt32 => Cell.Row_Span);
      elsif Method = "GetColumnExtentAt" then
         Cell := Resolve_Exposed_Cell (Snapshot, Row, Column, Limits, Result);
         if A11y.Results.Failed (Result) then
            return Error (Result.Status);
         end if;
         return
           (Kind   => UInt32_Reply,
            Status => A11y.Results.Success,
            UInt32 => Cell.Column_Span);
      elsif Method = "GetCurrentCell" then
         Node := A11y.Tables.Current_Cell (Snapshot.Table);
         if not A11y.Node_Ids.Is_Valid (Node)
           or else not Is_Externally_Exposed (Snapshot, Node, Limits)
         then
            return Error (A11y.Results.Node_Unavailable);
         end if;
         return
           (Kind   => Node_Reply,
            Status => A11y.Results.Success,
            Node   => Node);
      elsif Method = "GetSortOrder" then
         Sort := A11y.Tables.Current_Sort (Snapshot.Table);
         return
           (Kind   => UInt32_Reply,
            Status => A11y.Results.Success,
            UInt32 => A11y.Tables.Sort_Order'Pos (Sort.Order));
      elsif Method = "GetSortKey" then
         Sort := A11y.Tables.Current_Sort (Snapshot.Table);
         if not A11y.Node_Ids.Is_Valid (Sort.Key_Node)
           or else not Is_Externally_Exposed (Snapshot, Sort.Key_Node, Limits)
         then
            return Error (A11y.Results.Node_Unavailable);
         end if;
         return
           (Kind   => Node_Reply,
            Status => A11y.Results.Success,
            Node   => Sort.Key_Node);
      else
         return Error (A11y.Results.Unsupported_Capability);
      end if;
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Handle_Method;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Row      : A11y.Tables.Logical_Index;
      Column   : A11y.Tables.Logical_Index;
      Snapshot : Table_Method_Snapshot)
      return Table_Reply is
     (Handle_Method
        (Session, Path, Method, Row, Column, Snapshot, Snapshot.Limits));

end A11y.Linux.ATSPi_Table;
