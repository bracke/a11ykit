with A11y.Linux.ATSPi_Objects;
with A11y.Linux.DBus_Codec;
with A11y.Trees.Exposure_Views;

package body A11y.Linux.ATSPi_Document is
   use Ada.Strings.Unbounded;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Nodes.Exposure_Policy;

   function Error (Status : A11y.Results.Status_Code) return Document_Reply is
     (Kind       => Error_Reply,
      Status     => Status,
      Error_Name => To_Unbounded_String
        (A11y.Linux.ATSPi_Objects.Error_Name (Status)));

   function Exposure_Of
     (Snapshot : Document_Snapshot;
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
     (Snapshot : Document_Snapshot;
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

   function Document_Role_Name
     (Role : A11y.Documents.Document_Role)
      return String is
     (case Role is
        when A11y.Documents.Document => "document",
        when A11y.Documents.Article => "article",
        when A11y.Documents.Section => "section",
        when A11y.Documents.Chapter => "chapter",
        when A11y.Documents.Heading => "heading",
        when A11y.Documents.Paragraph => "paragraph",
        when A11y.Documents.Block_Quote => "block-quote",
        when A11y.Documents.List => "list",
        when A11y.Documents.List_Item => "list-item",
        when A11y.Documents.Code_Block => "code-block",
        when A11y.Documents.Figure => "figure",
        when A11y.Documents.Caption => "caption",
        when A11y.Documents.Footnote => "footnote",
        when A11y.Documents.Sidebar => "sidebar",
        when A11y.Documents.Navigation => "navigation",
        when A11y.Documents.Header => "header",
        when A11y.Documents.Footer => "footer",
        when A11y.Documents.Form => "form",
        when A11y.Documents.Region => "region",
        when A11y.Documents.Annotation => "annotation",
        when A11y.Documents.Embedded_Object => "embedded-object");

   function String_Attribute
     (Value  : Unbounded_String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return Document_Reply
   is
      Result : A11y.Results.Result;
      Encoded : A11y.Linux.DBus_Codec.DBus_Value;
   begin
      Encoded := A11y.Linux.DBus_Codec.Make_String
        (To_String (Value), Limits, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;
      return
        (Kind   => String_Reply,
         Status => A11y.Results.Success,
         Text   => Encoded.Text_Item);
   end String_Attribute;

   function Handle_Method
     (Session   : A11y.Native_Identity.Backend_Session_Id;
      Path      : String;
      Method    : String;
      Attribute : String;
      Snapshot  : Document_Snapshot;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config)
      return Document_Reply
   is
      Result : A11y.Results.Result;
      Node : A11y.Node_Ids.Node_Id;
      Encoded : A11y.Linux.DBus_Codec.DBus_Value;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      Node := A11y.Linux.ATSPi_Objects.Node_From_Object_Path
        (Path, Session, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      elsif Node /= Snapshot.Id or else Snapshot.Defunct
        or else not Is_Externally_Exposed (Snapshot, Limits)
      then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      Result := A11y.Documents.Validate (Snapshot.Metadata, Limits);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      if Method = "GetLocale" then
         return String_Attribute (Snapshot.Metadata.Language, Limits);
      elsif Method = "IsLandmark" then
         return
           (Kind         => Boolean_Reply,
            Status       => A11y.Results.Success,
            Boolean_Item => A11y.Documents.Is_Landmark (Snapshot.Metadata));
      elsif Method = "GetAttributeValue" then
         if Attribute = "title" then
            return String_Attribute (Snapshot.Metadata.Title, Limits);
         elsif Attribute = "author" then
            return String_Attribute (Snapshot.Metadata.Author, Limits);
         elsif Attribute = "subject" then
            return String_Attribute (Snapshot.Metadata.Subject, Limits);
         elsif Attribute = "version" then
            return String_Attribute (Snapshot.Metadata.Version, Limits);
         elsif Attribute = "revision" then
            return String_Attribute (Snapshot.Metadata.Revision, Limits);
         elsif Attribute = "creation" then
            return String_Attribute
              (Snapshot.Metadata.Creation_Metadata, Limits);
         elsif Attribute = "modification" then
            return String_Attribute
              (Snapshot.Metadata.Modification_Metadata, Limits);
         elsif Attribute = "landmark" then
            return String_Attribute (Snapshot.Metadata.Landmark, Limits);
         elsif Attribute = "role" then
            Encoded := A11y.Linux.DBus_Codec.Make_String
              (Document_Role_Name (Snapshot.Metadata.Role), Limits, Result);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;
            return
              (Kind   => String_Reply,
               Status => A11y.Results.Success,
               Text   => Encoded.Text_Item);
         elsif Attribute = "heading-level" then
            Encoded := A11y.Linux.DBus_Codec.Make_UInt32
              (Snapshot.Metadata.Heading_Level, Result);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;
            return
              (Kind   => UInt32_Reply,
               Status => A11y.Results.Success,
               UInt32 => Encoded.UInt32_Item);
         elsif Attribute = "page-count" then
            Encoded := A11y.Linux.DBus_Codec.Make_UInt32
              (Snapshot.Metadata.Page_Count, Result);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;
            return
              (Kind   => UInt32_Reply,
               Status => A11y.Results.Success,
               UInt32 => Encoded.UInt32_Item);
         elsif Attribute = "current-page" then
            Encoded := A11y.Linux.DBus_Codec.Make_UInt32
              (Snapshot.Metadata.Current_Page, Result);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;
            return
              (Kind   => UInt32_Reply,
               Status => A11y.Results.Success,
               UInt32 => Encoded.UInt32_Item);
         else
            return Error (A11y.Results.Unsupported_Property);
         end if;
      else
         return Error (A11y.Results.Unsupported_Capability);
      end if;
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Handle_Method;

   function Handle_Method
     (Session   : A11y.Native_Identity.Backend_Session_Id;
      Path      : String;
      Method    : String;
      Attribute : String;
      Snapshot  : Document_Snapshot)
      return Document_Reply is
     (Handle_Method
        (Session,
         Path,
         Method,
         Attribute,
         Snapshot,
         A11y.Resource_Limits.Default_Config));

end A11y.Linux.ATSPi_Document;
