with A11y.Linux.ATSPi_Objects;
with A11y.Linux.DBus_Codec;
with A11y.Trees.Exposure_Views;

package body A11y.Linux.ATSPi_Selection is
   use Ada.Strings.Unbounded;
   use type A11y.Node_Ids.Node_Id;

   function Error (Status : A11y.Results.Status_Code) return Selection_Reply is
     (Kind       => Error_Reply,
      Status     => Status,
      Error_Name => To_Unbounded_String
        (A11y.Linux.ATSPi_Objects.Error_Name (Status)));

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

   procedure Projected_Children
     (Snapshot : Selection_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Children : out A11y.Selection.Node_Vectors.Vector;
      Result   : out A11y.Results.Result)
   is
      Tree_Children : A11y.Trees.Child_Vectors.Vector;

      function Policy_For
        (Node : A11y.Node_Ids.Node_Id)
         return A11y.Nodes.Exposure_Policy is
        (Exposure_Of (Snapshot, Node));

      package Exposure_View is new A11y.Trees.Exposure_Views
        (Exposure_Of => Policy_For);
   begin
      Children := A11y.Selection.Node_Vectors.Empty_Vector;
      if not Snapshot.Use_Tree_Projection then
         Children := Snapshot.Children;
         Result := A11y.Results.Ok;
         return;
      elsif not A11y.Node_Ids.Is_Valid (Snapshot.Root)
        or else not Is_Externally_Exposed (Snapshot, Snapshot.Id, Limits)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      end if;

      Exposure_View.Exposed_Children_Of
        (Snapshot.Tree, Snapshot.Id, Limits, Tree_Children, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      for Child of Tree_Children loop
         Children.Append (Child);
      end loop;
      Result := A11y.Results.Ok;
   exception
      when others =>
         Children := A11y.Selection.Node_Vectors.Empty_Vector;
         Result := (Status => A11y.Results.Internal_Error);
   end Projected_Children;

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

   function Child_At
     (Snapshot : Selection_Snapshot;
      Index    : Natural;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id
   is
      Target : A11y.Node_Ids.Node_Id;
      Children : A11y.Selection.Node_Vectors.Vector;
   begin
      Projected_Children (Snapshot, Limits, Children, Result);
      if A11y.Results.Failed (Result) then
         return A11y.Node_Ids.No_Node;
      elsif Index >= Natural (Children.Length) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return A11y.Node_Ids.No_Node;
      end if;

      Target := Children (Positive (Index + 1));
      if not A11y.Node_Ids.Is_Valid (Target) then
         Result := (Status => A11y.Results.Node_Unavailable);
         return A11y.Node_Ids.No_Node;
      end if;

      Result := A11y.Results.Ok;
      return Target;
   end Child_At;

   function Selected_At
     (Snapshot : Selection_Snapshot;
      Index    : Natural;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id
   is
      Target : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Current : Natural := 0;
   begin
      if not Snapshot.Use_Tree_Projection then
         if Index >= A11y.Selection.Count (Snapshot.Selection) then
            Result := (Status => A11y.Results.Invalid_Argument);
            return A11y.Node_Ids.No_Node;
         end if;

         Target := A11y.Selection.Selected_At
           (Snapshot.Selection, Positive (Index + 1));
      else
         for Item of A11y.Selection.Items (Snapshot.Selection) loop
            if Is_Externally_Exposed (Snapshot, Item, Limits) then
               if Current = Index then
                  Target := Item;
                  exit;
               end if;
               Current := Current + 1;
            end if;
         end loop;

         if Current <= Index
           and then not A11y.Node_Ids.Is_Valid (Target)
         then
            Result := (Status => A11y.Results.Invalid_Argument);
            return A11y.Node_Ids.No_Node;
         end if;
      end if;

      if not A11y.Node_Ids.Is_Valid (Target) then
         Result := (Status => A11y.Results.Node_Unavailable);
         return A11y.Node_Ids.No_Node;
      end if;

      Result := A11y.Results.Ok;
      return Target;
   end Selected_At;

   procedure Select_All_Items
     (Snapshot : Selection_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Items    : out A11y.Selection.Node_Vectors.Vector;
      Result   : out A11y.Results.Result) is
   begin
      Projected_Children (Snapshot, Limits, Items, Result);
   exception
      when others =>
         Items := A11y.Selection.Node_Vectors.Empty_Vector;
         Result := (Status => A11y.Results.Internal_Error);
   end Select_All_Items;

   function Query_Direction
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Snapshot : Selection_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Selection_Reply
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

      Result := A11y.Selection.Validate (Snapshot.Selection);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      if Snapshot.Use_Tree_Projection
        and then
          (not A11y.Node_Ids.Is_Valid (Snapshot.Root)
           or else not Is_Externally_Exposed (Snapshot, Snapshot.Id, Limits))
      then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      return
        (Kind      => Direction_Reply,
         Status    => A11y.Results.Success,
         Direction => A11y.Selection.Direction (Snapshot.Selection));
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Query_Direction;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Index    : Natural;
      Snapshot : Selection_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Selection_Reply
   is
      Result : A11y.Results.Result;
      Node : A11y.Node_Ids.Node_Id;
      Target : A11y.Node_Ids.Node_Id;
      Encoded : A11y.Linux.DBus_Codec.DBus_Value;
      Candidate : A11y.Selection.Selection_Set;
      Selectable : A11y.Selection.Node_Vectors.Vector;
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

      Result := A11y.Selection.Validate (Snapshot.Selection);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      if Snapshot.Use_Tree_Projection
        and then
          (not A11y.Node_Ids.Is_Valid (Snapshot.Root)
           or else not Is_Externally_Exposed (Snapshot, Snapshot.Id, Limits))
      then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      if Method = "GetNSelectedChildren" then
         Encoded := A11y.Linux.DBus_Codec.Make_UInt32
           (Exposed_Selected_Count (Snapshot, Limits), Result);
         if A11y.Results.Failed (Result) then
            return Error (Result.Status);
         end if;
         return
           (Kind   => UInt32_Reply,
            Status => A11y.Results.Success,
            UInt32 => Encoded.UInt32_Item);
      elsif Method = "GetSelectedChild" then
         Target := Selected_At (Snapshot, Index, Limits, Result);
         if A11y.Results.Failed (Result) then
            return Error (Result.Status);
         end if;

         return
           (Kind   => Node_Reply,
            Status => A11y.Results.Success,
            Node   => Target,
            Request => Select_Child);
      elsif Method = "IsChildSelected" then
         Target := Child_At (Snapshot, Index, Limits, Result);
         if A11y.Results.Failed (Result) then
            return Error (Result.Status);
         end if;

         return
           (Kind         => Boolean_Reply,
            Status       => A11y.Results.Success,
            Boolean_Item => A11y.Selection.Contains
              (Snapshot.Selection, Target));
      elsif Method = "SelectChild" or else Method = "DeselectChild" then
         Target := Child_At (Snapshot, Index, Limits, Result);
         if A11y.Results.Failed (Result) then
            return Error (Result.Status);
         end if;

         Candidate := Snapshot.Selection;
         if Method = "SelectChild" then
            A11y.Selection.Select_Item (Candidate, Target, Result);
         else
            A11y.Selection.Deselect (Candidate, Target, Result);
         end if;

         if A11y.Results.Failed (Result) then
            return Error (Result.Status);
         end if;

         return
           (Kind   => Selection_Request_Reply,
            Status => A11y.Results.Success,
            Node   => Target,
            Request =>
              (if Method = "SelectChild" then
                 Select_Child
               else
                 Deselect_Child));
      elsif Method = "SelectAll" then
         Candidate := Snapshot.Selection;
         Select_All_Items (Snapshot, Limits, Selectable, Result);
         if A11y.Results.Succeeded (Result) then
            A11y.Selection.Select_All (Candidate, Selectable, Result);
         end if;

         if A11y.Results.Failed (Result) then
            return Error (Result.Status);
         end if;

         return
           (Kind   => Selection_Request_Reply,
            Status => A11y.Results.Success,
            Node   => A11y.Node_Ids.No_Node,
            Request => Select_All);
      elsif Method = "ClearSelection" then
         Candidate := Snapshot.Selection;
         A11y.Selection.Clear (Candidate, Result);
         if A11y.Results.Failed (Result) then
            return Error (Result.Status);
         end if;

         return
           (Kind   => Selection_Request_Reply,
            Status => A11y.Results.Success,
            Node   => A11y.Node_Ids.No_Node,
            Request => Clear_Selection);
      else
         return Error (A11y.Results.Unsupported_Capability);
      end if;
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Handle_Method;

   function Child_At
     (Snapshot : Selection_Snapshot;
      Index    : Natural;
      Result   : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id is
     (Child_At (Snapshot, Index, Snapshot.Limits, Result));

   function Query_Direction
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Snapshot : Selection_Snapshot)
      return Selection_Reply is
     (Query_Direction (Session, Path, Snapshot, Snapshot.Limits));

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Index    : Natural;
      Snapshot : Selection_Snapshot)
      return Selection_Reply is
     (Handle_Method
        (Session, Path, Method, Index, Snapshot, Snapshot.Limits));

end A11y.Linux.ATSPi_Selection;
