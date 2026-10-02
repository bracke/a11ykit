with A11y.Linux.ATSPi_Objects;
with A11y.Linux.DBus_Codec;
with A11y.Trees.Exposure_Views;

package body A11y.Linux.ATSPi_Text is
   use Ada.Strings.Unbounded;
   use Ada.Strings.Wide_Wide_Unbounded;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Nodes.Exposure_Policy;
   use type A11y.Results.Status_Code;

   function Error (Status : A11y.Results.Status_Code) return Text_Reply is
     (Kind       => Error_Reply,
      Status     => Status,
      Error_Name => To_Unbounded_String
        (A11y.Linux.ATSPi_Objects.Error_Name (Status)));

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

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Start    : Natural;
      Count    : Natural;
      Snapshot : Text_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Text_Reply
   is
      Result : A11y.Results.Result;
      Node : A11y.Node_Ids.Node_Id;
      Encoded : A11y.Linux.DBus_Codec.DBus_Value;
      Span : A11y.Text.Text_Range;
      Fragment : Unbounded_Wide_Wide_String;
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
      elsif not A11y.Text.Exposes_Text (Snapshot.Policy) then
         return Error (A11y.Results.Permission_Denied);
      end if;

      declare
         Content : constant Wide_Wide_String := To_Wide_Wide_String
           (Snapshot.Content);
      begin
         if Method = "GetCharacterCount" then
            Encoded := A11y.Linux.DBus_Codec.Make_UInt32
              (Content'Length, Result);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;
            return
              (Kind   => UInt32_Reply,
               Status => A11y.Results.Success,
               UInt32 => Encoded.UInt32_Item);
         elsif Method = "GetCaretOffset" then
            if not A11y.Text.Is_Within (Content'Length, Snapshot.Caret) then
               return Error (A11y.Results.Invalid_Range);
            end if;
            Encoded := A11y.Linux.DBus_Codec.Make_UInt32
              (A11y.Text.Index (Snapshot.Caret), Result);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;
            return
              (Kind   => UInt32_Reply,
               Status => A11y.Results.Success,
               UInt32 => Encoded.UInt32_Item);
         elsif Method = "GetText" then
            Span := A11y.Text.Bounded_Code_Point_Range
              (Content'Length, Start, Count, Limits, Result);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;
            Fragment := A11y.Text.Slice
              (Content, Span, Snapshot.Policy, Limits, Result);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;

            return
              (Kind      => Wide_Text_Reply,
               Status    => A11y.Results.Success,
               Wide_Text => Fragment);
         else
            return Error (A11y.Results.Unsupported_Capability);
         end if;
      end;
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Handle_Method;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Start    : Natural;
      Count    : Natural;
      Snapshot : Text_Snapshot)
      return Text_Reply is
     (Handle_Method
        (Session,
         Path,
         Method,
         Start,
         Count,
         Snapshot,
         A11y.Resource_Limits.Default_Config));

   function Edit_Kind_For_Method
     (Method : String;
      Result : out A11y.Results.Result)
      return A11y.Text.Text_Edit_Kind is
   begin
      if Method = "InsertText" then
         Result := A11y.Results.Ok;
         return A11y.Text.Insert_Text;
      elsif Method = "DeleteText" then
         Result := A11y.Results.Ok;
         return A11y.Text.Delete_Text;
      elsif Method = "ReplaceText" then
         Result := A11y.Results.Ok;
         return A11y.Text.Replace_Text;
      elsif Method = "SetTextContents" then
         Result := A11y.Results.Ok;
         return A11y.Text.Set_Text;
      end if;

      Result := (Status => A11y.Results.Unsupported_Capability);
      return A11y.Text.Insert_Text;
   end Edit_Kind_For_Method;

   function Handle_Edit_Method
     (Session     : A11y.Native_Identity.Backend_Session_Id;
      Path        : String;
      Method      : String;
      Start       : Natural;
      Count       : Natural;
      Replacement : Wide_Wide_String;
      Snapshot    : Text_Snapshot;
      Limits      : A11y.Resource_Limits.Resource_Limit_Config)
      return Text_Reply
   is
      Result : A11y.Results.Result;
      Node : A11y.Node_Ids.Node_Id;
      Kind : A11y.Text.Text_Edit_Kind;
      Request : A11y.Text.Text_Edit_Request;
      Policy_Status : A11y.Results.Status_Code;
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

      Kind := Edit_Kind_For_Method (Method, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      Policy_Status := A11y.Text.Edit_Policy_Status
        (Snapshot.Policy, Snapshot.Read_Only);
      if Policy_Status /= A11y.Results.Success then
         return Error (Policy_Status);
      end if;

      declare
         Content : constant Wide_Wide_String := To_Wide_Wide_String
           (Snapshot.Content);
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
   end Handle_Edit_Method;

   function Handle_Edit_Method
     (Session     : A11y.Native_Identity.Backend_Session_Id;
      Path        : String;
      Method      : String;
      Start       : Natural;
      Count       : Natural;
      Replacement : Wide_Wide_String;
      Snapshot    : Text_Snapshot)
      return Text_Reply is
     (Handle_Edit_Method
        (Session,
         Path,
         Method,
         Start,
         Count,
         Replacement,
         Snapshot,
         A11y.Resource_Limits.Default_Config));

   function Handle_Grapheme_Text_Range
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Start    : Natural;
      Count    : Natural;
      Snapshot : Text_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Text_Reply
   is
      Result : A11y.Results.Result;
      Node : A11y.Node_Ids.Node_Id;
      Fragment : Unbounded_Wide_Wide_String;
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
      elsif not A11y.Text.Exposes_Text (Snapshot.Policy) then
         return Error (A11y.Results.Permission_Denied);
      end if;

      declare
         Content : constant Wide_Wide_String := To_Wide_Wide_String
           (Snapshot.Content);
      begin
         Fragment := A11y.Text.Slice_Grapheme_Clusters
           (Content, Start, Count, Snapshot.Policy, Limits, Result);
         if A11y.Results.Failed (Result) then
            return Error (Result.Status);
         end if;
      end;

      return
        (Kind      => Wide_Text_Reply,
         Status    => A11y.Results.Success,
         Wide_Text => Fragment);
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Handle_Grapheme_Text_Range;

   function Handle_Grapheme_Text_Range
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Start    : Natural;
      Count    : Natural;
      Snapshot : Text_Snapshot)
      return Text_Reply is
     (Handle_Grapheme_Text_Range
        (Session,
         Path,
         Start,
         Count,
         Snapshot,
         A11y.Resource_Limits.Default_Config));

   function Handle_Grapheme_Edit_Method
     (Session     : A11y.Native_Identity.Backend_Session_Id;
      Path        : String;
      Method      : String;
      Start       : Natural;
      Count       : Natural;
      Replacement : Wide_Wide_String;
      Snapshot    : Text_Snapshot;
      Limits      : A11y.Resource_Limits.Resource_Limit_Config)
      return Text_Reply
   is
      Result : A11y.Results.Result;
      Node : A11y.Node_Ids.Node_Id;
      Kind : A11y.Text.Text_Edit_Kind;
      Request : A11y.Text.Text_Edit_Request;
      Policy_Status : A11y.Results.Status_Code;
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

      Kind := Edit_Kind_For_Method (Method, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      Policy_Status := A11y.Text.Edit_Policy_Status
        (Snapshot.Policy, Snapshot.Read_Only);
      if Policy_Status /= A11y.Results.Success then
         return Error (Policy_Status);
      end if;

      declare
         Content : constant Wide_Wide_String := To_Wide_Wide_String
           (Snapshot.Content);
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
   end Handle_Grapheme_Edit_Method;

   function Handle_Grapheme_Edit_Method
     (Session     : A11y.Native_Identity.Backend_Session_Id;
      Path        : String;
      Method      : String;
      Start       : Natural;
      Count       : Natural;
      Replacement : Wide_Wide_String;
      Snapshot    : Text_Snapshot)
      return Text_Reply is
     (Handle_Grapheme_Edit_Method
        (Session,
         Path,
         Method,
         Start,
         Count,
         Replacement,
         Snapshot,
         A11y.Resource_Limits.Default_Config));

end A11y.Linux.ATSPi_Text;
