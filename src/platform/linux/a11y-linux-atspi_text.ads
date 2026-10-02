with Ada.Strings.Unbounded;
with Ada.Strings.Wide_Wide_Unbounded;

with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Text;
with A11y.Trees;

package A11y.Linux.ATSPi_Text is

   type Exposure_Table is array (Natural range 0 .. 4_095) of
     A11y.Nodes.Exposure_Policy;

   type Text_Snapshot is record
      Id      : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Content : Ada.Strings.Wide_Wide_Unbounded.Unbounded_Wide_Wide_String;
      Policy  : A11y.Text.Protected_Text_Policy := A11y.Text.Plain_Text;
      Caret   : A11y.Text.Text_Position := A11y.Text.No_Position;
      Read_Only : Boolean := False;
      Root     : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Tree     : A11y.Trees.Semantic_Tree;
      Use_Tree_Projection : Boolean := False;
      Exposure : Exposure_Table := [others => A11y.Nodes.Expose_Node];
      Defunct : Boolean := False;
   end record;

   type Reply_Kind is
     (UInt32_Reply,
      Wide_Text_Reply,
      Edit_Request_Reply,
      Error_Reply);

   type Text_Reply (Kind : Reply_Kind := Error_Reply) is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      case Kind is
         when UInt32_Reply =>
            UInt32 : Natural := 0;
         when Wide_Text_Reply =>
            Wide_Text :
              Ada.Strings.Wide_Wide_Unbounded.Unbounded_Wide_Wide_String;
         when Edit_Request_Reply =>
            Requested_Edit : A11y.Text.Text_Edit_Request;
         when Error_Reply =>
            Error_Name : Ada.Strings.Unbounded.Unbounded_String;
      end case;
   end record;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Start    : Natural;
      Count    : Natural;
      Snapshot : Text_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Text_Reply;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Start    : Natural;
      Count    : Natural;
      Snapshot : Text_Snapshot)
      return Text_Reply;

   function Handle_Edit_Method
     (Session     : A11y.Native_Identity.Backend_Session_Id;
      Path        : String;
      Method      : String;
      Start       : Natural;
      Count       : Natural;
      Replacement : Wide_Wide_String;
      Snapshot    : Text_Snapshot;
      Limits      : A11y.Resource_Limits.Resource_Limit_Config)
      return Text_Reply;

   function Handle_Edit_Method
     (Session     : A11y.Native_Identity.Backend_Session_Id;
      Path        : String;
      Method      : String;
      Start       : Natural;
      Count       : Natural;
      Replacement : Wide_Wide_String;
      Snapshot    : Text_Snapshot)
      return Text_Reply;

   function Handle_Grapheme_Text_Range
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Start    : Natural;
      Count    : Natural;
      Snapshot : Text_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Text_Reply;

   function Handle_Grapheme_Text_Range
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Start    : Natural;
      Count    : Natural;
      Snapshot : Text_Snapshot)
      return Text_Reply;

   function Handle_Grapheme_Edit_Method
     (Session     : A11y.Native_Identity.Backend_Session_Id;
      Path        : String;
      Method      : String;
      Start       : Natural;
      Count       : Natural;
      Replacement : Wide_Wide_String;
      Snapshot    : Text_Snapshot;
      Limits      : A11y.Resource_Limits.Resource_Limit_Config)
      return Text_Reply;

   function Handle_Grapheme_Edit_Method
     (Session     : A11y.Native_Identity.Backend_Session_Id;
      Path        : String;
      Method      : String;
      Start       : Natural;
      Count       : Natural;
      Replacement : Wide_Wide_String;
      Snapshot    : Text_Snapshot)
      return Text_Reply;

end A11y.Linux.ATSPi_Text;
