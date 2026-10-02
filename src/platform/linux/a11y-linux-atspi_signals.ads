with Ada.Strings.Unbounded;

with A11y.Events;
with A11y.Geometry;
with A11y.Native_Identity;
with A11y.Native_Runtimes;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Trees;
with A11y.Values;

package A11y.Linux.ATSPi_Signals is

   type Exposure_Table is array (Natural range 0 .. 4_095) of
     A11y.Nodes.Exposure_Policy;

   type Signal_Context is record
      Session : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Root    : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Tree    : A11y.Trees.Semantic_Tree;
      Use_Tree_Projection : Boolean := False;
      Exposure : Exposure_Table := [others => A11y.Nodes.Expose_Node];
      Limits  : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
   end record;

   type Signal_Emission (Publishable : Boolean := False) is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      case Publishable is
         when True =>
            Object_Path : Ada.Strings.Unbounded.Unbounded_String;
            Event_Name  : Ada.Strings.Unbounded.Unbounded_String;
            Property_Detail : Ada.Strings.Unbounded.Unbounded_String;
            State_Detail : Ada.Strings.Unbounded.Unbounded_String;
            Relation_Detail : Ada.Strings.Unbounded.Unbounded_String;
            Has_Bounds_Payload : Boolean := False;
            Old_Bounds : A11y.Geometry.Rectangle :=
              A11y.Geometry.Empty_Rectangle;
            New_Bounds : A11y.Geometry.Rectangle :=
              A11y.Geometry.Empty_Rectangle;
            Has_Focus_Payload : Boolean := False;
            Old_Focus : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
            New_Focus : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
            Has_Node_Reference_Payload : Boolean := False;
            Old_Reference : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
            New_Reference : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
            Has_Value_Payload : Boolean := False;
            Old_Value : A11y.Values.Semantic_Value :=
              (Kind => A11y.Values.Unknown);
            New_Value : A11y.Values.Semantic_Value :=
              (Kind => A11y.Values.Unknown);
            Has_Selection_Payload : Boolean := False;
            Selection_Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
            Selection_Has_Node : Boolean := False;
            Selection_Old_Selected : Boolean := False;
            Selection_New_Selected : Boolean := False;
            Selection_Required : Boolean := False;
            Has_Live_Region_Payload : Boolean := False;
            Live_Region_Payload : A11y.Events.Live_Region_Event_Payload;
            Has_Tree_Payload : Boolean := False;
            Tree_Payload : A11y.Events.Tree_Event_Payload;
            Has_Table_Payload : Boolean := False;
            Table_Payload : A11y.Events.Table_Event_Payload;
            Has_Document_Payload : Boolean := False;
            Document_Payload : A11y.Events.Document_Event_Payload;
            Has_Window_Payload : Boolean := False;
            Window_Payload : A11y.Events.Window_Event_Payload;
            Sequence    : A11y.Event_Sequence := A11y.No_Event;
            Revision    : A11y.Semantic_Revision := A11y.Initial_Revision;
         when False =>
            Error_Name  : Ada.Strings.Unbounded.Unbounded_String;
      end case;
   end record;

   type Signal_Build_Report is record
      Source               : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Sequence             : A11y.Event_Sequence := A11y.No_Event;
      Revision             : A11y.Semantic_Revision := A11y.Initial_Revision;
      Envelope_Valid       : Boolean := False;
      Source_Exposed       : Boolean := True;
      Prepared_Input       : Boolean := False;
      Prepared_Has_Object  : Boolean := False;
      Prepared_Destroys_Node : Boolean := False;
      Object_Path_Resolved : Boolean := False;
      Publishable          : Boolean := False;
      Status               : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
   end record;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event)
      return Signal_Emission;

   procedure Build_Signal_With_Report
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Signal  : out Signal_Emission;
      Report  : out Signal_Build_Report);

   function Build_Signal
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Prepared : A11y.Native_Runtimes.Prepared_Event)
      return Signal_Emission;

   procedure Build_Signal_With_Report
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Signal   : out Signal_Emission;
      Report   : out Signal_Build_Report);

   function Build_Signal
     (Context : Signal_Context;
      Event   : A11y.Events.Event)
      return Signal_Emission;

   procedure Build_Signal_With_Report
     (Context : Signal_Context;
      Event   : A11y.Events.Event;
      Signal  : out Signal_Emission;
      Report  : out Signal_Build_Report);

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.Property_Event_Payload)
      return Signal_Emission;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.State_Event_Payload)
      return Signal_Emission;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.Relation_Event_Payload)
      return Signal_Emission;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.Bounds_Event_Payload)
      return Signal_Emission;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.Focus_Event_Payload)
      return Signal_Emission;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.Node_Reference_Event_Payload)
      return Signal_Emission;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.Value_Event_Payload)
      return Signal_Emission;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.Selection_Event_Payload)
      return Signal_Emission;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.Live_Region_Event_Payload)
      return Signal_Emission;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.Tree_Event_Payload)
      return Signal_Emission;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.Table_Event_Payload)
      return Signal_Emission;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.Document_Event_Payload)
      return Signal_Emission;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.Window_Event_Payload)
      return Signal_Emission;

end A11y.Linux.ATSPi_Signals;
