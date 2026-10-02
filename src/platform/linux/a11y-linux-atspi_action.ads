with Ada.Strings.Unbounded;

with A11y.Actions;
with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.States;
with A11y.Trees;

package A11y.Linux.ATSPi_Action is

   type Exposure_Table is array (Natural range 0 .. 4_095) of
     A11y.Nodes.Exposure_Policy;

   type Action_Snapshot is record
      Id        : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Root      : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Tree      : A11y.Trees.Semantic_Tree;
      Use_Tree_Projection : Boolean := False;
      Exposure  : Exposure_Table := [others => A11y.Nodes.Expose_Node];
      Supported : A11y.Actions.Action_Set := A11y.Actions.Empty_Action_Set;
      States    : A11y.States.State_Set :=
        A11y.States.With_State
          (A11y.States.Empty_State_Set, A11y.States.Enabled);
      Defunct   : Boolean := False;
   end record;

   type Reply_Kind is
     (UInt32_Reply,
      String_Reply,
      Invocation_Reply,
      Error_Reply);

   type Action_Reply (Kind : Reply_Kind := Error_Reply) is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      case Kind is
         when UInt32_Reply =>
            UInt32 : Natural := 0;
         when String_Reply =>
            Text : Ada.Strings.Unbounded.Unbounded_String;
         when Invocation_Reply =>
            Action : A11y.Actions.Action_Id := A11y.Actions.Activate;
         when Error_Reply =>
            Error_Name : Ada.Strings.Unbounded.Unbounded_String;
      end case;
   end record;

   function Action_Count (Supported : A11y.Actions.Action_Set) return Natural;

   function Action_At
     (Supported : A11y.Actions.Action_Set;
      Index     : Natural;
      Result    : out A11y.Results.Result)
      return A11y.Actions.Action_Id;

   function Action_Name (Action : A11y.Actions.Action_Id) return String;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Index    : Natural;
      Snapshot : Action_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Action_Reply;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Index    : Natural;
      Snapshot : Action_Snapshot)
      return Action_Reply;

end A11y.Linux.ATSPi_Action;
