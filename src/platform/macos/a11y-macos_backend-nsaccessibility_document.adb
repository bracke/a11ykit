with A11y.Trees.Exposure_Views;

package body A11y.MacOS_Backend.NSAccessibility_Document is
   use Ada.Strings.Unbounded;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Nodes.Exposure_Policy;

   function Error
     (Status : A11y.Results.Status_Code)
      return Document_Reply is
     (Kind => Error_Reply, Status => Status);

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

   function String_Reply_For
     (Text : Unbounded_String)
      return Document_Reply is
     (Kind   => String_Reply,
      Status => A11y.Results.Success,
      Text   => Text);

   function Query_Document
     (Snapshot : Document_Snapshot;
      Query    : Document_Query;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Document_Reply is
      Result : A11y.Results.Result;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      if Snapshot.Defunct
        or else not Is_Externally_Exposed (Snapshot, Limits)
      then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      Result := A11y.Documents.Validate (Snapshot.Metadata, Limits);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      case Query is
         when Locale =>
            return String_Reply_For (Snapshot.Metadata.Language);
         when Title =>
            return String_Reply_For (Snapshot.Metadata.Title);
         when Author =>
            return String_Reply_For (Snapshot.Metadata.Author);
         when Subject =>
            return String_Reply_For (Snapshot.Metadata.Subject);
         when Version =>
            return String_Reply_For (Snapshot.Metadata.Version);
         when Revision =>
            return String_Reply_For (Snapshot.Metadata.Revision);
         when Creation =>
            return String_Reply_For (Snapshot.Metadata.Creation_Metadata);
         when Modification =>
            return String_Reply_For (Snapshot.Metadata.Modification_Metadata);
         when Landmark =>
            return String_Reply_For (Snapshot.Metadata.Landmark);
         when Role =>
            return String_Reply_For
              (To_Unbounded_String
                 (Document_Role_Name (Snapshot.Metadata.Role)));
         when Heading_Level =>
            return
              (Kind   => UInt32_Reply,
               Status => A11y.Results.Success,
               UInt32 => Snapshot.Metadata.Heading_Level);
         when Page_Count =>
            return
              (Kind   => UInt32_Reply,
               Status => A11y.Results.Success,
               UInt32 => Snapshot.Metadata.Page_Count);
         when Current_Page =>
            return
              (Kind   => UInt32_Reply,
               Status => A11y.Results.Success,
               UInt32 => Snapshot.Metadata.Current_Page);
         when Is_Landmark =>
            return
              (Kind         => Boolean_Reply,
               Status       => A11y.Results.Success,
               Boolean_Item =>
                 A11y.Documents.Is_Landmark (Snapshot.Metadata));
      end case;
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Query_Document;

   function Query_Document
     (Snapshot : Document_Snapshot;
      Query    : Document_Query)
      return Document_Reply is
     (Query_Document
        (Snapshot, Query, A11y.Resource_Limits.Default_Config));

end A11y.MacOS_Backend.NSAccessibility_Document;
