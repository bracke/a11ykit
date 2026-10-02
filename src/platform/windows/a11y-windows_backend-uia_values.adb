with A11y.Trees.Exposure_Views;

package body A11y.Windows_Backend.UIA_Values is
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Nodes.Exposure_Policy;
   use type A11y.Results.Status_Code;
   use type A11y.Values.Access_Mode;

   function Error (Status : A11y.Results.Status_Code) return Value_Reply is
     (Kind   => Error_Reply,
      Status => Status);

   function Numeric_Reply
     (Item : A11y.Values.Semantic_Value)
      return Value_Reply
   is
      Result : A11y.Results.Result;
      Converted : constant Long_Float :=
        A11y.Values.To_Long_Float_Lossless (Item, Result);
   begin
      if A11y.Results.Failed (Result) then
         if Result.Status = A11y.Results.Unsupported_Property then
            return
              (Kind   => Not_Supported_Reply,
               Status => Result.Status);
         end if;
         return Error (Result.Status);
      end if;

      return
        (Kind       => Float_Reply,
         Status     => A11y.Results.Success,
         Float_Item => Converted);
   end Numeric_Reply;

   function Exposure_Of
     (Snapshot : Value_Snapshot;
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
     (Snapshot : Value_Snapshot;
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
        or else not A11y.Node_Ids.Is_Valid (Snapshot.Id)
      then
         return False;
      elsif Snapshot.Id = Snapshot.Root then
         return Exposure_Of (Snapshot, Snapshot.Id) = A11y.Nodes.Expose_Node;
      end if;

      Parent := Exposure_View.Exposed_Parent_Of
        (Snapshot.Tree, Snapshot.Id, Limits, Result);
      return A11y.Results.Succeeded (Result)
        and then A11y.Node_Ids.Is_Valid (Parent);
   exception
      when others =>
         return False;
   end Is_Externally_Exposed;

   function Query_Value
     (Snapshot : Value_Snapshot;
      Query    : Value_Query;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Value_Reply
   is
      Result : A11y.Results.Result;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      elsif Snapshot.Defunct or else not Is_Externally_Exposed (Snapshot, Limits)
      then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      Result := A11y.Values.Validate (Snapshot.Metadata, Limits);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      case Query is
         when Current_Value =>
            return Numeric_Reply (Snapshot.Metadata.Current);
         when Minimum_Value =>
            return Numeric_Reply (Snapshot.Metadata.Minimum);
         when Maximum_Value =>
            return Numeric_Reply (Snapshot.Metadata.Maximum);
         when Small_Increment =>
            return Numeric_Reply (Snapshot.Metadata.Small_Increment);
         when Large_Increment =>
            return Numeric_Reply (Snapshot.Metadata.Large_Increment);
         when Is_Read_Only =>
            return
              (Kind         => Boolean_Reply,
               Status       => A11y.Results.Success,
               Boolean_Item =>
                 Snapshot.Metadata.Mode = A11y.Values.Read_Only);
      end case;
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Query_Value;

   function Query_Value
     (Snapshot : Value_Snapshot;
      Query    : Value_Query)
     return Value_Reply is
     (Query_Value
        (Snapshot, Query, A11y.Resource_Limits.Default_Config));

   function Request_Value_Set
     (Snapshot        : Value_Snapshot;
      Requested_Value : A11y.Values.Semantic_Value;
      Limits          : A11y.Resource_Limits.Resource_Limit_Config)
      return Value_Reply
   is
      Result : A11y.Results.Result;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      elsif Snapshot.Defunct or else not Is_Externally_Exposed (Snapshot, Limits)
      then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      Result := A11y.Values.Validate_Numeric_Set_Request
        (Snapshot.Metadata, Requested_Value, Limits);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      return
        (Kind            => Set_Request_Reply,
         Status          => A11y.Results.Success,
         Requested_Value => Requested_Value);
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Request_Value_Set;

   function Request_Value_Set
     (Snapshot        : Value_Snapshot;
      Requested_Value : A11y.Values.Semantic_Value)
      return Value_Reply is
     (Request_Value_Set
        (Snapshot, Requested_Value, A11y.Resource_Limits.Default_Config));

end A11y.Windows_Backend.UIA_Values;
