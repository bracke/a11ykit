with Ada.Strings.Unbounded;

with A11y.Geometry;
with A11y.Images;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Trees;

package A11y.Windows_Backend.UIA_Image is

   type Image_Query is
     (Description,
      Caption,
      Kind_Name,
      Intrinsic_Size);

   type Exposure_Table is
     array (Positive range 1 .. A11y.Trees.Max_Attached_Nodes)
       of A11y.Nodes.Exposure_Policy;

   type Image_Snapshot is record
      Id       : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Root     : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Metadata : A11y.Images.Image_Metadata;
      Tree     : A11y.Trees.Semantic_Tree;
      Use_Tree_Projection : Boolean := False;
      Exposure : Exposure_Table := [others => A11y.Nodes.Expose_Node];
      Defunct  : Boolean := False;
   end record;

   type Reply_Kind is
     (String_Reply,
      Size_Reply,
      Error_Reply);

   type Image_Reply (Kind : Reply_Kind := Error_Reply) is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      case Kind is
         when String_Reply =>
            Text : Ada.Strings.Unbounded.Unbounded_String;
         when Size_Reply =>
            Size : A11y.Geometry.Size;
         when Error_Reply =>
            null;
      end case;
   end record;

   function Query_Image
     (Snapshot : Image_Snapshot;
      Query    : Image_Query;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Image_Reply;

   function Query_Image
     (Snapshot : Image_Snapshot;
      Query    : Image_Query)
      return Image_Reply;

end A11y.Windows_Backend.UIA_Image;
