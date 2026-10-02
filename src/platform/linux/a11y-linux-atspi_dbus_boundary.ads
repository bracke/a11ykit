with Ada.Strings.Unbounded;

with A11y.Actions;
with A11y.Geometry;
with A11y.Linux.ATSPi_Accessible;
with A11y.Linux.ATSPi_Mappings;
with A11y.Linux.ATSPi_Method_Router;
with A11y.Linux.ATSPi_Object_Registry;
with A11y.Linux.ATSPi_Selection;
with A11y.Linux.DBus_Codec;
with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Results;
with A11y.Tables;
with A11y.Text;
with A11y.Trees;
with A11y.Values;

package A11y.Linux.ATSPi_DBus_Boundary is

   type DBus_Method_Call is record
      Session        : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Method_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Index          : Natural := 0;
      Count          : Natural := 0;
      Point          : A11y.Geometry.Point := (X => 0, Y => 0);
      Row            : A11y.Tables.Logical_Index := 0;
      Column         : A11y.Tables.Logical_Index := 0;
      Attribute      : Ada.Strings.Unbounded.Unbounded_String;
      Attribute_2    : Ada.Strings.Unbounded.Unbounded_String;
      Requested_Value : A11y.Values.Semantic_Value :=
        (Kind => A11y.Values.Unknown);
   end record;

   type DBus_Reply_Kind is
     (Method_Reply,
      Error_Reply);

   type DBus_Method_Reply (Kind : DBus_Reply_Kind := Error_Reply) is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      case Kind is
         when Method_Reply =>
            Routed_Kind :
              A11y.Linux.ATSPi_Method_Router.Routed_Reply_Kind :=
                A11y.Linux.ATSPi_Method_Router.Routed_Error;
            Text : Ada.Strings.Unbounded.Unbounded_String;
            UInt32 : Natural := 0;
            Int32 : Integer := 0;
            Boolean_Item : Boolean := False;
            Float_Item : Long_Float := 0.0;
            Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
            Nodes : A11y.Trees.Child_Vectors.Vector;
            Strings : A11y.Linux.DBus_Codec.String_Vectors.Vector;
            Bounds : A11y.Geometry.Rectangle :=
              A11y.Geometry.Empty_Rectangle;
            Size : A11y.Geometry.Size := (Width => 0, Height => 0);
            State_Set : A11y.Linux.ATSPi_Mappings.ATSPI_State_Set :=
              A11y.Linux.ATSPi_Mappings.Empty_ATSPI_State_Set;
            Attributes :
              A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Vector;
            Relations :
              A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Vector;
            Requested_Action : A11y.Actions.Action_Id := A11y.Actions.Activate;
            Requested_Value : A11y.Values.Semantic_Value :=
              (Kind => A11y.Values.Unknown);
            Selection_Request :
              A11y.Linux.ATSPi_Selection.Selection_Request_Kind :=
                A11y.Linux.ATSPi_Selection.Select_Child;
            Requested_Edit : A11y.Text.Text_Edit_Request;
         when Error_Reply =>
            Error_Name : Ada.Strings.Unbounded.Unbounded_String;
      end case;
   end record;

   type Registered_Call_Boundary_Report is record
      Resolved          : Boolean := False;
      Native_Admitted   : Boolean := False;
      Native_Completed  : Boolean := False;
      Resolved_Object   :
        A11y.Linux.ATSPi_Object_Registry.Object_Record_Snapshot;
      Begin_Report      :
        A11y.Linux.ATSPi_Object_Registry.Native_Call_Mutation_Report;
      End_Report        :
        A11y.Linux.ATSPi_Object_Registry.Native_Call_Mutation_Report;
      Reply_Status      : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      Final_Status      : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
   end record;

   function Dispatch_Call
     (Call      : DBus_Method_Call;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle)
      return DBus_Method_Reply;

   function Dispatch_Registered_Call
     (Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Call      : DBus_Method_Call;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle)
      return DBus_Method_Reply;

   function Dispatch_Registered_Call_With_Report
     (Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Call      : DBus_Method_Call;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Report    : out Registered_Call_Boundary_Report)
      return DBus_Method_Reply;

end A11y.Linux.ATSPi_DBus_Boundary;
