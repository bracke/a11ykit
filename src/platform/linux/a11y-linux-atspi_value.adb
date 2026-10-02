with A11y.Linux.ATSPi_Objects;
with A11y.Trees.Exposure_Views;

package body A11y.Linux.ATSPi_Value is
   use Ada.Strings.Unbounded;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Nodes.Exposure_Policy;

   function Error (Status : A11y.Results.Status_Code) return Value_Reply is
     (Kind       => Error_Reply,
      Status     => Status,
      Error_Name => To_Unbounded_String
        (A11y.Linux.ATSPi_Objects.Error_Name (Status)));

   function Numeric_Reply (Value : A11y.Values.Semantic_Value) return Value_Reply is
      Result : A11y.Results.Result;
      Converted : constant Long_Float := A11y.Values.To_Long_Float_Lossless
        (Value, Result);
   begin
      if A11y.Results.Failed (Result) then
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

   function Handle_Method
     (Session         : A11y.Native_Identity.Backend_Session_Id;
      Path            : String;
      Method          : String;
      Requested_Value : A11y.Values.Semantic_Value;
      Snapshot        : Value_Snapshot;
      Limits          : A11y.Resource_Limits.Resource_Limit_Config)
      return Value_Reply
   is
      Result : A11y.Results.Result;
      Node : A11y.Node_Ids.Node_Id;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      Node := A11y.Linux.ATSPi_Objects.Node_From_Object_Path
        (Path, Session, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      elsif Node /= Snapshot.Id
        or else Snapshot.Defunct
        or else not Is_Externally_Exposed (Snapshot, Limits)
      then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      Result := A11y.Values.Validate (Snapshot.Metadata, Limits);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      if Method = "GetCurrentValue" then
         return Numeric_Reply (Snapshot.Metadata.Current);
      elsif Method = "GetMinimumValue" then
         return Numeric_Reply (Snapshot.Metadata.Minimum);
      elsif Method = "GetMaximumValue" then
         return Numeric_Reply (Snapshot.Metadata.Maximum);
      elsif Method = "GetMinimumIncrement" then
         return Numeric_Reply (Snapshot.Metadata.Small_Increment);
      elsif Method = "SetCurrentValue" then
         Result := A11y.Values.Validate_Numeric_Set_Request
           (Snapshot.Metadata, Requested_Value, Limits);
         if A11y.Results.Failed (Result) then
            return Error (Result.Status);
         end if;

         return
           (Kind            => Set_Request_Reply,
            Status          => A11y.Results.Success,
            Requested_Value => Requested_Value);
      else
         return Error (A11y.Results.Unsupported_Capability);
      end if;
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Handle_Method;

   function Handle_Method
     (Session         : A11y.Native_Identity.Backend_Session_Id;
      Path            : String;
      Method          : String;
      Requested_Value : A11y.Values.Semantic_Value;
      Snapshot        : Value_Snapshot)
      return Value_Reply is
     (Handle_Method
        (Session,
         Path,
         Method,
         Requested_Value,
         Snapshot,
         A11y.Resource_Limits.Default_Config));

end A11y.Linux.ATSPi_Value;
