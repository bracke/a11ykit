with Ada.Strings.Unbounded;

with A11y.Resource_Limits;
with A11y.Results;

package A11y.Documents is

   type Document_Role is
     (Document,
      Article,
      Section,
      Chapter,
      Heading,
      Paragraph,
      Block_Quote,
      List,
      List_Item,
      Code_Block,
      Figure,
      Caption,
      Footnote,
      Sidebar,
      Navigation,
      Header,
      Footer,
      Form,
      Region,
      Annotation,
      Embedded_Object);

   type Document_Role_Metadata is record
      Stable_Name       : access constant String;
      Landmark_By_Role  : Boolean := False;
      Structural_Block  : Boolean := True;
   end record;

   type Document_Metadata is record
      Role          : Document_Role := Document;
      Heading_Level : Natural := 0;
      Language      : Ada.Strings.Unbounded.Unbounded_String;
      Title         : Ada.Strings.Unbounded.Unbounded_String;
      Author        : Ada.Strings.Unbounded.Unbounded_String;
      Subject       : Ada.Strings.Unbounded.Unbounded_String;
      Version       : Ada.Strings.Unbounded.Unbounded_String;
      Revision      : Ada.Strings.Unbounded.Unbounded_String;
      Creation_Metadata     : Ada.Strings.Unbounded.Unbounded_String;
      Modification_Metadata : Ada.Strings.Unbounded.Unbounded_String;
      Landmark      : Ada.Strings.Unbounded.Unbounded_String;
      Page_Count    : Natural := 0;
      Current_Page  : Natural := 0;
   end record;

   function Metadata (Role : Document_Role) return Document_Role_Metadata;

   function Stable_Name (Role : Document_Role) return String;

   function Is_Landmark_Role
     (Role : Document_Role)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Is_Landmark_Role'Result =
         (Role in Navigation | Header | Footer | Form | Region);

   function Is_Structural_Block_Role
     (Role : Document_Role)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Is_Structural_Block_Role'Result =
         (Role not in Annotation | Embedded_Object);

   function Valid_Heading_Level (Level : Natural) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Valid_Heading_Level'Result = (Level <= 9);
   function Heading_Level_Applies (Item : Document_Metadata) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Heading_Level_Applies'Result =
         Heading_Level_Applies (Item.Role, Item.Heading_Level);
   function Heading_Level_Applies
     (Role  : Document_Role;
      Level : Natural)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Heading_Level_Applies'Result =
         ((Role = Heading and then Level in 1 .. 9)
          or else (Role /= Heading and then Level = 0));
   function Is_Landmark (Item : Document_Metadata) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Is_Landmark'Result =
         (Ada.Strings.Unbounded.Length (Item.Landmark) > 0
          or else Is_Landmark_Role (Item.Role));
   function Has_Pagination (Item : Document_Metadata) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Has_Pagination'Result = (Item.Page_Count > 0);
   function Pagination_Applies (Item : Document_Metadata) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Pagination_Applies'Result =
         Pagination_Applies
           (Item.Role, Item.Page_Count, Item.Current_Page);
   function Pagination_Applies
     (Role         : Document_Role;
      Page_Count   : Natural;
      Current_Page : Natural)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Pagination_Applies'Result =
         ((Page_Count = 0 and then Current_Page = 0)
          or else
            (Is_Structural_Block_Role (Role)
             and then Page_Count > 0
             and then Current_Page in 1 .. Page_Count));

   function Validate
     (Item   : Document_Metadata;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return A11y.Results.Result;

   function Validate
     (Item : Document_Metadata)
      return A11y.Results.Result;

   type Document_Provider is limited interface;

   function Current_Metadata
     (Self : Document_Provider)
      return Document_Metadata is abstract;

   function Current_Metadata_Safely
     (Self   : Document_Provider'Class;
      Result : out A11y.Results.Result)
      return Document_Metadata;

end A11y.Documents;
