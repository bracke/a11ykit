with A11y.Linux.ATSPi_Objects;
with A11y.Trees.Exposure_Views;

package body A11y.Linux.ATSPi_Component is
   use Ada.Strings.Unbounded;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Results.Status_Code;

   function Error (Status : A11y.Results.Status_Code) return Component_Reply is
     (Kind       => Error_Reply,
      Status     => Status,
      Error_Name => To_Unbounded_String
        (A11y.Linux.ATSPi_Objects.Error_Name (Status)));

   function Exposure_Of
     (Snapshot : Component_Snapshot;
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
     (Snapshot : Component_Snapshot;
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

   function Projected_Hit_Test_Node
     (Snapshot : Component_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id is
   begin
      if not Snapshot.Use_Tree_Projection then
         Result := A11y.Results.Ok;
         return Snapshot.Hit_Test_Node;
      elsif not A11y.Node_Ids.Is_Valid (Snapshot.Root)
        or else not Is_Externally_Exposed (Snapshot, Snapshot.Id, Limits)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return A11y.Node_Ids.No_Node;
      elsif not A11y.Node_Ids.Is_Valid (Snapshot.Hit_Test_Node)
        or else not Is_Externally_Exposed
          (Snapshot, Snapshot.Hit_Test_Node, Limits)
      then
         Result := A11y.Results.Ok;
         return A11y.Node_Ids.No_Node;
      end if;

      Result := A11y.Results.Ok;
      return Snapshot.Hit_Test_Node;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return A11y.Node_Ids.No_Node;
   end Projected_Hit_Test_Node;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Point    : A11y.Geometry.Point;
      Snapshot : Component_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Component_Reply
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
      elsif Node /= Snapshot.Id or else Snapshot.Defunct then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      if Method = "GetExtents" then
         return
           (Kind   => Rectangle_Reply,
            Status => A11y.Results.Success,
            Bounds => Snapshot.Bounds);
      elsif Method = "Contains" then
         return
           (Kind         => Boolean_Reply,
            Status       => A11y.Results.Success,
            Boolean_Item => A11y.Geometry.Contains (Snapshot.Bounds, Point));
      elsif Method = "GetAccessibleAtPoint" then
         if A11y.Geometry.Contains (Snapshot.Bounds, Point) then
            declare
               Target : constant A11y.Node_Ids.Node_Id :=
                 Projected_Hit_Test_Node (Snapshot, Limits, Result);
            begin
               if A11y.Results.Failed (Result) then
                  return Error (Result.Status);
               end if;

               return
                 (Kind   => Node_Reply,
                  Status => A11y.Results.Success,
                  Node   => Target);
            end;
         else
            return
              (Kind   => Node_Reply,
              Status => A11y.Results.Success,
              Node   => A11y.Node_Ids.No_Node);
         end if;
      elsif Method = "GrabFocus" then
         if not Snapshot.Focus_Request_Supported then
            return Error (A11y.Results.Unsupported_Action);
         elsif Snapshot.Focus_Request_Status /= A11y.Results.Success then
            return Error (Snapshot.Focus_Request_Status);
         else
            return
              (Kind         => Boolean_Reply,
               Status       => A11y.Results.Success,
               Boolean_Item => True);
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
      Point    : A11y.Geometry.Point;
      Snapshot : Component_Snapshot)
      return Component_Reply is
     (Handle_Method
        (Session, Path, Method, Point, Snapshot, Snapshot.Limits));

end A11y.Linux.ATSPi_Component;
