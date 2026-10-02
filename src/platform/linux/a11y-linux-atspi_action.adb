with A11y.Linux.ATSPi_Objects;
with A11y.Linux.DBus_Codec;
with A11y.Trees.Exposure_Views;

package body A11y.Linux.ATSPi_Action is
   use Ada.Strings.Unbounded;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Nodes.Exposure_Policy;
   use type A11y.Results.Status_Code;

   function Error (Status : A11y.Results.Status_Code) return Action_Reply is
     (Kind       => Error_Reply,
      Status     => Status,
      Error_Name => To_Unbounded_String
        (A11y.Linux.ATSPi_Objects.Error_Name (Status)));

   function Action_Count (Supported : A11y.Actions.Action_Set) return Natural is
      Count : Natural := 0;
   begin
      for Action in A11y.Actions.Action_Id loop
         if Supported (Action) then
            Count := Count + 1;
         end if;
      end loop;

      return Count;
   end Action_Count;

   function Action_At
     (Supported : A11y.Actions.Action_Set;
      Index     : Natural;
      Result    : out A11y.Results.Result)
      return A11y.Actions.Action_Id
   is
      Current : Natural := 0;
   begin
      for Action in A11y.Actions.Action_Id loop
         if Supported (Action) then
            if Current = Index then
               Result := A11y.Results.Ok;
               return Action;
            end if;
            Current := Current + 1;
         end if;
      end loop;

      Result := (Status => A11y.Results.Invalid_Argument);
      return A11y.Actions.Activate;
   end Action_At;

   function Action_Name (Action : A11y.Actions.Action_Id) return String is
     (A11y.Actions.Stable_Name (Action));

   function Exposure_Of
     (Snapshot : Action_Snapshot;
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
     (Snapshot : Action_Snapshot;
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
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Index    : Natural;
      Snapshot : Action_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Action_Reply
   is
      Result : A11y.Results.Result;
      Node : A11y.Node_Ids.Node_Id;
      Encoded : A11y.Linux.DBus_Codec.DBus_Value;
      Requested : A11y.Actions.Action_Id;
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

      if Method = "GetNActions" then
         Encoded := A11y.Linux.DBus_Codec.Make_UInt32
           (Action_Count (Snapshot.Supported), Result);
         if A11y.Results.Failed (Result) then
            return Error (Result.Status);
         end if;
         return
           (Kind   => UInt32_Reply,
            Status => A11y.Results.Success,
            UInt32 => Encoded.UInt32_Item);
      elsif Method = "GetName" or else Method = "DoAction" then
         Requested := Action_At (Snapshot.Supported, Index, Result);
         if A11y.Results.Failed (Result) then
            return Error (Result.Status);
         end if;

         if Method = "GetName" then
            Encoded := A11y.Linux.DBus_Codec.Make_String
              (Action_Name (Requested), Limits, Result);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;
            return
              (Kind   => String_Reply,
               Status => A11y.Results.Success,
               Text   => Encoded.Text_Item);
         else
            declare
               Validation : constant A11y.Actions.Action_Result :=
                 A11y.Actions.Validate_Request
                   (Snapshot.Supported, Requested, Snapshot.States);
            begin
               if Validation.Status /= A11y.Results.Success then
                  return Error (Validation.Status);
               end if;
            end;

            return
              (Kind   => Invocation_Reply,
               Status => A11y.Results.Success,
               Action => Requested);
         end if;
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
      Index    : Natural;
      Snapshot : Action_Snapshot)
      return Action_Reply is
     (Handle_Method
        (Session, Path, Method, Index, Snapshot,
         A11y.Resource_Limits.Default_Config));

end A11y.Linux.ATSPi_Action;
