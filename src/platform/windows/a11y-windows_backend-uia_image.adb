with A11y.Trees.Exposure_Views;

package body A11y.Windows_Backend.UIA_Image is
   use Ada.Strings.Unbounded;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Nodes.Exposure_Policy;

   function Error (Status : A11y.Results.Status_Code) return Image_Reply is
     (Kind => Error_Reply, Status => Status);

   function Exposure_Of
     (Snapshot : Image_Snapshot;
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
     (Snapshot : Image_Snapshot;
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

   function Description (Metadata : A11y.Images.Image_Metadata)
      return Unbounded_String is
   begin
      if Length (Metadata.Alternative_Text) > 0 then
         return Metadata.Alternative_Text;
      end if;

      return Metadata.Long_Description;
   end Description;

   function Query_Image
     (Snapshot : Image_Snapshot;
      Query    : Image_Query;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Image_Reply is
      Result : A11y.Results.Result;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      if Snapshot.Defunct
        or else not A11y.Images.Should_Expose (Snapshot.Metadata)
        or else not Is_Externally_Exposed (Snapshot, Limits)
      then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      Result := A11y.Images.Validate (Snapshot.Metadata, Limits);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      case Query is
         when Description =>
            if not A11y.Images.Has_Text_Alternative (Snapshot.Metadata) then
               return Error (A11y.Results.Unsupported_Property);
            end if;

            return
              (Kind   => String_Reply,
               Status => A11y.Results.Success,
               Text   => Description (Snapshot.Metadata));
         when Caption =>
            if not A11y.Images.Has_Caption (Snapshot.Metadata) then
               return Error (A11y.Results.Unsupported_Property);
            end if;

            return
              (Kind   => String_Reply,
               Status => A11y.Results.Success,
               Text   => Snapshot.Metadata.Caption);
         when Kind_Name =>
            return
              (Kind   => String_Reply,
               Status => A11y.Results.Success,
               Text   => To_Unbounded_String
                 (A11y.Images.Stable_Name (Snapshot.Metadata.Kind)));
         when Intrinsic_Size =>
            if not Snapshot.Metadata.Has_Intrinsic_Size then
               return Error (A11y.Results.Unsupported_Property);
            end if;

            return
              (Kind   => Size_Reply,
               Status => A11y.Results.Success,
               Size   => Snapshot.Metadata.Intrinsic_Dimensions);
      end case;
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Query_Image;

   function Query_Image
     (Snapshot : Image_Snapshot;
      Query    : Image_Query)
      return Image_Reply is
     (Query_Image
        (Snapshot, Query, A11y.Resource_Limits.Default_Config));

end A11y.Windows_Backend.UIA_Image;
