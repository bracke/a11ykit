with A11y.Trees.Exposure_Views;

package body A11y.MacOS_Backend.NSAccessibility_Text is
   use Ada.Strings.Wide_Wide_Unbounded;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Nodes.Exposure_Policy;
   use type A11y.Results.Status_Code;

   function Error (Status : A11y.Results.Status_Code) return Text_Reply is
     (Kind   => Error_Reply,
      Status => Status);

   function Exposure_Of
     (Snapshot : Text_Snapshot;
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
     (Snapshot : Text_Snapshot;
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

   function Query_Text
     (Snapshot : Text_Snapshot;
      Query    : Text_Query;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Start    : Natural := 0;
      Count    : Natural := 0)
      return Text_Reply
   is
      Result : A11y.Results.Result;
      Span : A11y.Text.Text_Range;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      elsif Snapshot.Defunct or else not Is_Externally_Exposed (Snapshot, Limits)
      then
         return Error (A11y.Results.Node_Unavailable);
      elsif not A11y.Text.Exposes_Text (Snapshot.Policy) then
         return Error (A11y.Results.Permission_Denied);
      end if;

      declare
         Content : constant Wide_Wide_String :=
           To_Wide_Wide_String (Snapshot.Content);
      begin
         case Query is
         when Character_Count =>
            return
              (Kind   => UInt32_Reply,
               Status => A11y.Results.Success,
               UInt32 => Content'Length);
         when Grapheme_Cluster_Count =>
            return
              (Kind   => UInt32_Reply,
               Status => A11y.Results.Success,
               UInt32 => A11y.Text.Grapheme_Cluster_Count (Content));
         when Grapheme_Text_Range =>
            declare
               Fragment : constant Unbounded_Wide_Wide_String :=
                 A11y.Text.Slice_Grapheme_Clusters
                   (Content,
                    Start,
                    Count,
                    Snapshot.Policy,
                    Limits,
                    Result);
            begin
               if A11y.Results.Failed (Result) then
                  return Error (Result.Status);
               end if;

               return
                 (Kind      => Wide_Text_Reply,
                  Status    => A11y.Results.Success,
                  Wide_Text => Fragment);
            end;
         when Text_Range =>
            Span := A11y.Text.Bounded_Code_Point_Range
              (Content'Length, Start, Count, Limits, Result);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;

            declare
               Fragment : constant Unbounded_Wide_Wide_String :=
                 A11y.Text.Slice
                   (Content, Span, Snapshot.Policy, Limits, Result);
            begin
               if A11y.Results.Failed (Result) then
                  return Error (Result.Status);
               end if;

               return
                 (Kind      => Wide_Text_Reply,
                  Status    => A11y.Results.Success,
                  Wide_Text => Fragment);
            end;
         when Caret_Offset =>
            if not A11y.Text.Is_Within (Content'Length, Snapshot.Caret) then
               return Error (A11y.Results.Invalid_Range);
            end if;

            return
              (Kind   => UInt32_Reply,
               Status => A11y.Results.Success,
               UInt32 => A11y.Text.Index (Snapshot.Caret));
         when UTF16_Unit_Count =>
            Span := A11y.Text.Bounded_Code_Point_Range
              (Content'Length, Start, Count, Limits, Result);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;

            declare
               Units : constant Natural :=
                 A11y.Text.UTF_16_Units (Content, Span, Result);
            begin
               if A11y.Results.Failed (Result) then
                  return Error (Result.Status);
               end if;

               return
                 (Kind   => UInt32_Reply,
                  Status => A11y.Results.Success,
                  UInt32 => Units);
            end;
         end case;
      end;
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Query_Text;

   function Query_Text
     (Snapshot : Text_Snapshot;
      Query    : Text_Query;
      Start    : Natural := 0;
      Count    : Natural := 0)
      return Text_Reply is
     (Query_Text
        (Snapshot,
         Query,
         A11y.Resource_Limits.Default_Config,
         Start,
         Count));

   function Request_Text_Edit
     (Snapshot    : Text_Snapshot;
      Kind        : A11y.Text.Text_Edit_Kind;
      Limits      : A11y.Resource_Limits.Resource_Limit_Config;
      Start       : Natural := 0;
      Count       : Natural := 0;
      Replacement : Wide_Wide_String := "")
      return Text_Reply
   is
      Result : A11y.Results.Result;
      Request : A11y.Text.Text_Edit_Request;
      Policy_Status : A11y.Results.Status_Code;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      elsif Snapshot.Defunct or else not Is_Externally_Exposed (Snapshot, Limits)
      then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      Policy_Status := A11y.Text.Edit_Policy_Status
        (Snapshot.Policy, Snapshot.Read_Only);
      if Policy_Status /= A11y.Results.Success then
         return Error (Policy_Status);
      end if;

      declare
         Content : constant Wide_Wide_String :=
           To_Wide_Wide_String (Snapshot.Content);
      begin
         Request := A11y.Text.Validate_Edit_Request
           (Content'Length,
            Kind,
            Start,
            Count,
            Replacement,
            Snapshot.Policy,
            Snapshot.Read_Only,
            Limits,
            Result);
         if A11y.Results.Failed (Result) then
            return Error (Result.Status);
         end if;
      end;

      return
        (Kind           => Edit_Request_Reply,
         Status         => A11y.Results.Success,
         Requested_Edit => Request);
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Request_Text_Edit;

   function Request_Text_Edit
     (Snapshot    : Text_Snapshot;
      Kind        : A11y.Text.Text_Edit_Kind;
      Start       : Natural := 0;
      Count       : Natural := 0;
      Replacement : Wide_Wide_String := "")
      return Text_Reply is
     (Request_Text_Edit
        (Snapshot,
         Kind,
         A11y.Resource_Limits.Default_Config,
         Start,
         Count,
         Replacement));

   function Request_Grapheme_Text_Edit
     (Snapshot    : Text_Snapshot;
      Kind        : A11y.Text.Text_Edit_Kind;
      Limits      : A11y.Resource_Limits.Resource_Limit_Config;
      Start       : Natural := 0;
      Count       : Natural := 0;
      Replacement : Wide_Wide_String := "")
      return Text_Reply
   is
      Result : A11y.Results.Result;
      Request : A11y.Text.Text_Edit_Request;
      Policy_Status : A11y.Results.Status_Code;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      elsif Snapshot.Defunct or else not Is_Externally_Exposed (Snapshot, Limits)
      then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      Policy_Status := A11y.Text.Edit_Policy_Status
        (Snapshot.Policy, Snapshot.Read_Only);
      if Policy_Status /= A11y.Results.Success then
         return Error (Policy_Status);
      end if;

      declare
         Content : constant Wide_Wide_String :=
           To_Wide_Wide_String (Snapshot.Content);
      begin
         Request := A11y.Text.Validate_Grapheme_Edit_Request
           (Content,
            Kind,
            Start,
            Count,
            Replacement,
            Snapshot.Policy,
            Snapshot.Read_Only,
            Limits,
            Result);
         if A11y.Results.Failed (Result) then
            return Error (Result.Status);
         end if;
      end;

      return
        (Kind           => Edit_Request_Reply,
         Status         => A11y.Results.Success,
         Requested_Edit => Request);
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Request_Grapheme_Text_Edit;

   function Request_Grapheme_Text_Edit
     (Snapshot    : Text_Snapshot;
      Kind        : A11y.Text.Text_Edit_Kind;
      Start       : Natural := 0;
      Count       : Natural := 0;
      Replacement : Wide_Wide_String := "")
      return Text_Reply is
     (Request_Grapheme_Text_Edit
        (Snapshot,
         Kind,
         A11y.Resource_Limits.Default_Config,
         Start,
         Count,
         Replacement));

end A11y.MacOS_Backend.NSAccessibility_Text;
