package body A11y.Documents is
   use Ada.Strings.Unbounded;
   use type A11y.Resource_Limits.Limit_Value;

   Document_Name        : aliased constant String := "document";
   Article_Name         : aliased constant String := "article";
   Section_Name         : aliased constant String := "section";
   Chapter_Name         : aliased constant String := "chapter";
   Heading_Name         : aliased constant String := "heading";
   Paragraph_Name       : aliased constant String := "paragraph";
   Block_Quote_Name     : aliased constant String := "block-quote";
   List_Name            : aliased constant String := "list";
   List_Item_Name       : aliased constant String := "list-item";
   Code_Block_Name      : aliased constant String := "code-block";
   Figure_Name          : aliased constant String := "figure";
   Caption_Name         : aliased constant String := "caption";
   Footnote_Name        : aliased constant String := "footnote";
   Sidebar_Name         : aliased constant String := "sidebar";
   Navigation_Name      : aliased constant String := "navigation";
   Header_Name          : aliased constant String := "header";
   Footer_Name          : aliased constant String := "footer";
   Form_Name            : aliased constant String := "form";
   Region_Name          : aliased constant String := "region";
   Annotation_Name      : aliased constant String := "annotation";
   Embedded_Object_Name : aliased constant String := "embedded-object";

   function Metadata (Role : Document_Role) return Document_Role_Metadata is
     (case Role is
        when Document =>
          (Stable_Name => Document_Name'Access,
           Landmark_By_Role => False,
           Structural_Block => True),
        when Article =>
          (Stable_Name => Article_Name'Access,
           Landmark_By_Role => False,
           Structural_Block => True),
        when Section =>
          (Stable_Name => Section_Name'Access,
           Landmark_By_Role => False,
           Structural_Block => True),
        when Chapter =>
          (Stable_Name => Chapter_Name'Access,
           Landmark_By_Role => False,
           Structural_Block => True),
        when Heading =>
          (Stable_Name => Heading_Name'Access,
           Landmark_By_Role => False,
           Structural_Block => True),
        when Paragraph =>
          (Stable_Name => Paragraph_Name'Access,
           Landmark_By_Role => False,
           Structural_Block => True),
        when Block_Quote =>
          (Stable_Name => Block_Quote_Name'Access,
           Landmark_By_Role => False,
           Structural_Block => True),
        when List =>
          (Stable_Name => List_Name'Access,
           Landmark_By_Role => False,
           Structural_Block => True),
        when List_Item =>
          (Stable_Name => List_Item_Name'Access,
           Landmark_By_Role => False,
           Structural_Block => True),
        when Code_Block =>
          (Stable_Name => Code_Block_Name'Access,
           Landmark_By_Role => False,
           Structural_Block => True),
        when Figure =>
          (Stable_Name => Figure_Name'Access,
           Landmark_By_Role => False,
           Structural_Block => True),
        when Caption =>
          (Stable_Name => Caption_Name'Access,
           Landmark_By_Role => False,
           Structural_Block => True),
        when Footnote =>
          (Stable_Name => Footnote_Name'Access,
           Landmark_By_Role => False,
           Structural_Block => True),
        when Sidebar =>
          (Stable_Name => Sidebar_Name'Access,
           Landmark_By_Role => False,
           Structural_Block => True),
        when Navigation =>
          (Stable_Name => Navigation_Name'Access,
           Landmark_By_Role => True,
           Structural_Block => True),
        when Header =>
          (Stable_Name => Header_Name'Access,
           Landmark_By_Role => True,
           Structural_Block => True),
        when Footer =>
          (Stable_Name => Footer_Name'Access,
           Landmark_By_Role => True,
           Structural_Block => True),
        when Form =>
          (Stable_Name => Form_Name'Access,
           Landmark_By_Role => True,
           Structural_Block => True),
        when Region =>
          (Stable_Name => Region_Name'Access,
           Landmark_By_Role => True,
           Structural_Block => True),
        when Annotation =>
          (Stable_Name => Annotation_Name'Access,
           Landmark_By_Role => False,
           Structural_Block => False),
        when Embedded_Object =>
          (Stable_Name => Embedded_Object_Name'Access,
           Landmark_By_Role => False,
           Structural_Block => False));

   function Stable_Name (Role : Document_Role) return String is
     (Metadata (Role).Stable_Name.all);

   function Is_Landmark_Role
     (Role : Document_Role)
      return Boolean is
     (Role in Navigation | Header | Footer | Form | Region)
   with SPARK_Mode => On;

   function Is_Structural_Block_Role
     (Role : Document_Role)
      return Boolean is
     (Role not in Annotation | Embedded_Object)
   with SPARK_Mode => On;

   function Valid_Heading_Level (Level : Natural) return Boolean is
     (Level <= 9)
   with SPARK_Mode => On;

   function Heading_Level_Applies (Item : Document_Metadata) return Boolean is
     (Heading_Level_Applies (Item.Role, Item.Heading_Level))
   with SPARK_Mode => On;

   function Heading_Level_Applies
     (Role  : Document_Role;
      Level : Natural)
      return Boolean is
     ((Role = Heading and then Level in 1 .. 9)
      or else (Role /= Heading and then Level = 0))
   with SPARK_Mode => On;

   function Is_Landmark (Item : Document_Metadata) return Boolean is
     (Length (Item.Landmark) > 0
      or else Is_Landmark_Role (Item.Role))
   with SPARK_Mode => On;

   function Has_Pagination (Item : Document_Metadata) return Boolean is
     (Item.Page_Count > 0)
   with SPARK_Mode => On;

   function Pagination_Applies (Item : Document_Metadata) return Boolean is
     (Pagination_Applies (Item.Role, Item.Page_Count, Item.Current_Page))
   with SPARK_Mode => On;

   function Pagination_Applies
     (Role         : Document_Role;
      Page_Count   : Natural;
      Current_Page : Natural)
      return Boolean is
     ((Page_Count = 0 and then Current_Page = 0)
      or else
        (Is_Structural_Block_Role (Role)
         and then Page_Count > 0
         and then Current_Page in 1 .. Page_Count))
   with SPARK_Mode => On;

   function Text_Exceeds
     (Value  : Unbounded_String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return Boolean is
     (A11y.Resource_Limits.Limit_Value (Length (Value))
      > A11y.Resource_Limits.Value
          (Limits, A11y.Resource_Limits.Text_Returned))
   with SPARK_Mode => On;

   function Validate
     (Item   : Document_Metadata;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return A11y.Results.Result
   is
      Result : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
   begin
      if A11y.Results.Failed (Result) then
         return Result;
      elsif not Valid_Heading_Level (Item.Heading_Level) then
         return (Status => A11y.Results.Invalid_Range);
      elsif not Heading_Level_Applies (Item) then
         return (Status => A11y.Results.Invalid_State);
      elsif not Pagination_Applies (Item) then
         return (Status => A11y.Results.Invalid_Range);
      elsif Text_Exceeds (Item.Language, Limits)
        or else Text_Exceeds (Item.Title, Limits)
        or else Text_Exceeds (Item.Author, Limits)
        or else Text_Exceeds (Item.Subject, Limits)
        or else Text_Exceeds (Item.Version, Limits)
        or else Text_Exceeds (Item.Revision, Limits)
        or else Text_Exceeds (Item.Creation_Metadata, Limits)
        or else Text_Exceeds (Item.Modification_Metadata, Limits)
        or else Text_Exceeds (Item.Landmark, Limits)
      then
         return (Status => A11y.Results.Resource_Limit);
      else
         return A11y.Results.Ok;
      end if;
   end Validate;

   function Validate
     (Item : Document_Metadata)
      return A11y.Results.Result is
     (Validate (Item, A11y.Resource_Limits.Default_Config));

   function Current_Metadata_Safely
     (Self   : Document_Provider'Class;
      Result : out A11y.Results.Result)
      return Document_Metadata
   is
      Item : Document_Metadata;
   begin
      Item := Self.Current_Metadata;
      Result := Validate (Item);
      if A11y.Results.Failed (Result) then
         return (Role                  => Document,
                 Heading_Level         => 0,
                 Language              => <>,
                 Title                 => <>,
                 Author                => <>,
                 Subject               => <>,
                 Version               => <>,
                 Revision              => <>,
                 Creation_Metadata     => <>,
                 Modification_Metadata => <>,
                 Landmark              => <>,
                 Page_Count            => 0,
                 Current_Page          => 0);
      end if;
      return Item;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return (Role                  => Document,
                 Heading_Level         => 0,
                 Language              => <>,
                 Title                 => <>,
                 Author                => <>,
                 Subject               => <>,
                 Version               => <>,
                 Revision              => <>,
                 Creation_Metadata     => <>,
                 Modification_Metadata => <>,
                 Landmark              => <>,
                 Page_Count            => 0,
                 Current_Page          => 0);
   end Current_Metadata_Safely;

end A11y.Documents;
