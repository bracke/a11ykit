with A11y.Linux.ATSPi_Mappings;
with A11y.Linux.ATSPi_Objects;
with A11y.Properties;
with A11y.Relations;
with A11y.States;
with A11y.Trees.Exposure_Views;

package body A11y.Linux.ATSPi_Signals is
   use Ada.Strings.Unbounded;
   use type A11y.Events.Event_Kind;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Nodes.Exposure_Policy;
   use type A11y.Results.Status_Code;

   function Error (Status : A11y.Results.Status_Code) return Signal_Emission is
     (Publishable => False,
      Status      => Status,
      Error_Name  => To_Unbounded_String
        (A11y.Linux.ATSPi_Objects.Error_Name (Status)));

   procedure Finish_Report
     (Signal : Signal_Emission;
      Report : in out Signal_Build_Report) is
   begin
      Report.Publishable := Signal.Publishable;
      Report.Status := Signal.Status;
      if Signal.Publishable then
         Report.Object_Path_Resolved := Length (Signal.Object_Path) > 0;
      end if;
   end Finish_Report;

   function Property_Detail
     (Property : A11y.Properties.Property_Id)
      return String is
     (case Property is
        when A11y.Properties.Accessible_Name =>
          "accessible-name",
        when A11y.Properties.Visible_Title =>
          "visible-title",
        when A11y.Properties.Description =>
          "accessible-description",
        when A11y.Properties.Help_Text =>
          "help-text",
        when A11y.Properties.Placeholder =>
          "placeholder-text",
        when A11y.Properties.Value_Text =>
          "accessible-value",
        when A11y.Properties.Keyboard_Shortcut =>
          "keyboard-shortcut",
        when A11y.Properties.Semantic_Identifier =>
          "semantic-identifier",
        when A11y.Properties.Locale =>
          "locale",
        when A11y.Properties.Bounds =>
          "bounds",
        when A11y.Properties.Orientation =>
          "orientation",
        when A11y.Properties.Set_Position =>
          "set-position",
        when A11y.Properties.Set_Size =>
          "set-size",
        when A11y.Properties.Hierarchical_Level =>
          "level",
        when A11y.Properties.Heading_Level =>
          "heading-level",
        when A11y.Properties.Landmark =>
          "landmark",
        when A11y.Properties.Role_Property =>
          "role",
        when A11y.Properties.State_Property =>
          "state");

   function Exposure_Of
     (Context : Signal_Context;
      Node    : A11y.Node_Ids.Node_Id)
      return A11y.Nodes.Exposure_Policy
   is
      Slot : constant Natural := A11y.Node_Ids.To_Natural (Node);
   begin
      if Slot not in Context.Exposure'Range then
         return A11y.Nodes.Hide_Node_And_Subtree;
      end if;

      return Context.Exposure (Slot);
   end Exposure_Of;

   function Is_Source_Externally_Exposed
     (Context : Signal_Context;
      Source  : A11y.Node_Ids.Node_Id)
      return Boolean
   is
      function Policy_For
        (Current : A11y.Node_Ids.Node_Id)
         return A11y.Nodes.Exposure_Policy is
        (Exposure_Of (Context, Current));

      package Exposure_View is new A11y.Trees.Exposure_Views
        (Exposure_Of => Policy_For);
   begin
      if not Context.Use_Tree_Projection then
         return True;
      elsif not A11y.Node_Ids.Is_Valid (Context.Root)
        or else not A11y.Node_Ids.Is_Valid (Source)
      then
         return False;
      end if;

      return Exposure_View.Is_Externally_Exposed
        (Context.Tree, Source, Context.Limits);
   exception
      when others =>
         return False;
   end Is_Source_Externally_Exposed;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event)
      return Signal_Emission
   is
      Envelope_Result : constant A11y.Results.Result :=
        A11y.Events.Validate_Event (Event);
      Result : A11y.Results.Result;
      Path : Unbounded_String;
   begin
      if A11y.Results.Failed (Envelope_Result) then
         return Error (Envelope_Result.Status);
      end if;

      Path := A11y.Linux.ATSPi_Objects.Object_Path
        (Session, Event.Source, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Object_Path => Path,
         Event_Name  => To_Unbounded_String
           (A11y.Linux.ATSPi_Mappings.Event_Name (Event.Kind)),
         Property_Detail => Null_Unbounded_String,
         State_Detail => Null_Unbounded_String,
         Relation_Detail => Null_Unbounded_String,
         Has_Bounds_Payload => False,
         Old_Bounds => A11y.Geometry.Empty_Rectangle,
         New_Bounds => A11y.Geometry.Empty_Rectangle,
         Has_Focus_Payload => False,
         Old_Focus => A11y.Node_Ids.No_Node,
         New_Focus => A11y.Node_Ids.No_Node,
         Has_Node_Reference_Payload => False,
         Old_Reference => A11y.Node_Ids.No_Node,
         New_Reference => A11y.Node_Ids.No_Node,
         Has_Value_Payload => False,
         Old_Value => (Kind => A11y.Values.Unknown),
         New_Value => (Kind => A11y.Values.Unknown),
         Has_Selection_Payload => False,
         Selection_Node => A11y.Node_Ids.No_Node,
         Selection_Has_Node => False,
         Selection_Old_Selected => False,
         Selection_New_Selected => False,
         Selection_Required => False,
         Has_Live_Region_Payload => False,
         Live_Region_Payload => <>,
         Has_Tree_Payload => False,
         Tree_Payload => <>,
         Has_Table_Payload => False,
         Table_Payload => <>,
         Has_Document_Payload => False,
         Document_Payload => <>,
         Has_Window_Payload => False,
         Window_Payload => <>,

         Sequence    => Event.Sequence,
         Revision    => Event.Revision);
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Build_Signal;

   procedure Build_Signal_With_Report
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Signal  : out Signal_Emission;
      Report  : out Signal_Build_Report)
   is
      Envelope_Result : constant A11y.Results.Result :=
        A11y.Events.Validate_Event (Event);
   begin
      Report :=
        (Source                 => Event.Source,
         Sequence               => Event.Sequence,
         Revision               => Event.Revision,
         Envelope_Valid         => A11y.Results.Succeeded (Envelope_Result),
         Source_Exposed         => True,
         Prepared_Input         => False,
         Prepared_Has_Object    => False,
         Prepared_Destroys_Node => False,
         Object_Path_Resolved   => False,
         Publishable            => False,
         Status                 => Envelope_Result.Status);
      Signal := Build_Signal (Session, Event);
      Finish_Report (Signal, Report);
   exception
      when others =>
         Signal := Error (A11y.Results.Internal_Error);
         Report.Status := A11y.Results.Internal_Error;
         Report.Publishable := False;
         Report.Object_Path_Resolved := False;
   end Build_Signal_With_Report;

   function Build_Signal
     (Context : Signal_Context;
      Event   : A11y.Events.Event)
      return Signal_Emission is
   begin
      if not Is_Source_Externally_Exposed (Context, Event.Source) then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      return Build_Signal (Context.Session, Event);
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Build_Signal;

   procedure Build_Signal_With_Report
     (Context : Signal_Context;
      Event   : A11y.Events.Event;
      Signal  : out Signal_Emission;
      Report  : out Signal_Build_Report)
   is
      Envelope_Result : constant A11y.Results.Result :=
        A11y.Events.Validate_Event (Event);
      Exposed : constant Boolean :=
        Is_Source_Externally_Exposed (Context, Event.Source);
   begin
      Report :=
        (Source                 => Event.Source,
         Sequence               => Event.Sequence,
         Revision               => Event.Revision,
         Envelope_Valid         => A11y.Results.Succeeded (Envelope_Result),
         Source_Exposed         => Exposed,
         Prepared_Input         => False,
         Prepared_Has_Object    => False,
         Prepared_Destroys_Node => False,
         Object_Path_Resolved   => False,
         Publishable            => False,
         Status                 =>
           (if not Exposed then A11y.Results.Node_Unavailable
            else Envelope_Result.Status));
      Signal := Build_Signal (Context, Event);
      Finish_Report (Signal, Report);
   exception
      when others =>
         Signal := Error (A11y.Results.Internal_Error);
         Report.Status := A11y.Results.Internal_Error;
         Report.Publishable := False;
         Report.Object_Path_Resolved := False;
   end Build_Signal_With_Report;

   function Build_Signal
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Prepared : A11y.Native_Runtimes.Prepared_Event)
      return Signal_Emission
   is
      Validation : constant A11y.Results.Result :=
        A11y.Native_Runtimes.Validate_Prepared_Event (Prepared);
   begin
      if A11y.Results.Failed (Validation) then
         return Error (Validation.Status);
      end if;

      if Prepared.Has_Property_Payload then
         return Build_Signal
           (Session, Prepared.Event, Prepared.Property_Payload);
      elsif Prepared.Has_State_Payload then
         return Build_Signal
           (Session, Prepared.Event, Prepared.State_Payload);
      elsif Prepared.Has_Bounds_Payload then
         return Build_Signal
           (Session, Prepared.Event, Prepared.Bounds_Payload);
      elsif Prepared.Has_Value_Payload then
         return Build_Signal
           (Session, Prepared.Event, Prepared.Value_Payload);
      elsif Prepared.Has_Selection_Payload then
         return Build_Signal
           (Session, Prepared.Event, Prepared.Selection_Payload);
      elsif Prepared.Has_Relation_Payload then
         return Build_Signal
           (Session, Prepared.Event, Prepared.Relation_Payload);
      elsif Prepared.Has_Focus_Payload then
         return Build_Signal
           (Session, Prepared.Event, Prepared.Focus_Payload);
      elsif Prepared.Has_Node_Reference_Payload then
         return Build_Signal
           (Session, Prepared.Event, Prepared.Node_Reference_Payload);
      elsif Prepared.Has_Live_Region_Payload then
         return Build_Signal
           (Session, Prepared.Event, Prepared.Live_Region_Payload);
      elsif Prepared.Has_Tree_Payload then
         return Build_Signal
           (Session, Prepared.Event, Prepared.Tree_Payload);
      elsif Prepared.Has_Table_Payload then
         return Build_Signal
           (Session, Prepared.Event, Prepared.Table_Payload);
      elsif Prepared.Has_Document_Payload then
         return Build_Signal
           (Session, Prepared.Event, Prepared.Document_Payload);
      elsif Prepared.Has_Window_Payload then
         return Build_Signal
           (Session, Prepared.Event, Prepared.Window_Payload);
      else
         return Build_Signal (Session, Prepared.Event);
      end if;
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Build_Signal;

   procedure Build_Signal_With_Report
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Signal   : out Signal_Emission;
      Report   : out Signal_Build_Report)
   is
      Envelope_Result : constant A11y.Results.Result :=
        A11y.Events.Validate_Event (Prepared.Event);
   begin
      Report :=
        (Source                 => Prepared.Event.Source,
         Sequence               => Prepared.Event.Sequence,
         Revision               => Prepared.Event.Revision,
         Envelope_Valid         => A11y.Results.Succeeded (Envelope_Result),
         Source_Exposed         => True,
         Prepared_Input         => True,
         Prepared_Has_Object    => Prepared.Has_Object,
         Prepared_Destroys_Node => Prepared.Destroys_Node,
         Object_Path_Resolved   => False,
         Publishable            => False,
         Status                 =>
           (if A11y.Results.Failed ((Status => Prepared.Status)) then
              Prepared.Status
            else
              Envelope_Result.Status));
      Signal := Build_Signal (Session, Prepared);
      Finish_Report (Signal, Report);
   exception
      when others =>
         Signal := Error (A11y.Results.Internal_Error);
         Report.Status := A11y.Results.Internal_Error;
         Report.Publishable := False;
         Report.Object_Path_Resolved := False;
   end Build_Signal_With_Report;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.Property_Event_Payload)
      return Signal_Emission
   is
      Signal : constant Signal_Emission := Build_Signal (Session, Event);
      Result : A11y.Results.Result := A11y.Results.Ok;
      Validated_Payload : A11y.Events.Property_Event_Payload;
   begin
      if not Signal.Publishable then
         return Signal;
      end if;

      Validated_Payload := A11y.Events.Validate_Property_Event_Payload
        (Kind    => Event.Kind,
         Payload => Payload,
         Result  => Result);

      if Result.Status /= A11y.Results.Success then
         return Error (Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Object_Path => Signal.Object_Path,
         Event_Name  => Signal.Event_Name,
         Property_Detail => To_Unbounded_String
           (Property_Detail (Validated_Payload.Property)),
         State_Detail => Null_Unbounded_String,
         Relation_Detail => Null_Unbounded_String,
         Has_Bounds_Payload => Signal.Has_Bounds_Payload,
         Old_Bounds => Signal.Old_Bounds,
         New_Bounds => Signal.New_Bounds,
         Has_Focus_Payload => Signal.Has_Focus_Payload,
         Old_Focus => Signal.Old_Focus,
         New_Focus => Signal.New_Focus,
         Has_Node_Reference_Payload => Signal.Has_Node_Reference_Payload,
         Old_Reference => Signal.Old_Reference,
         New_Reference => Signal.New_Reference,
         Has_Value_Payload => Signal.Has_Value_Payload,
         Old_Value => Signal.Old_Value,
         New_Value => Signal.New_Value,
         Has_Selection_Payload => Signal.Has_Selection_Payload,
         Selection_Node => Signal.Selection_Node,
         Selection_Has_Node => Signal.Selection_Has_Node,
         Selection_Old_Selected => Signal.Selection_Old_Selected,
         Selection_New_Selected => Signal.Selection_New_Selected,
         Selection_Required => Signal.Selection_Required,
         Has_Live_Region_Payload => Signal.Has_Live_Region_Payload,
         Live_Region_Payload => Signal.Live_Region_Payload,
         Has_Tree_Payload => Signal.Has_Tree_Payload,
         Tree_Payload => Signal.Tree_Payload,
         Has_Table_Payload => Signal.Has_Table_Payload,
         Table_Payload => Signal.Table_Payload,
         Has_Document_Payload => Signal.Has_Document_Payload,
         Document_Payload => Signal.Document_Payload,
         Has_Window_Payload => Signal.Has_Window_Payload,
         Window_Payload => Signal.Window_Payload,
         Sequence    => Signal.Sequence,
         Revision    => Signal.Revision);
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Build_Signal;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.State_Event_Payload)
      return Signal_Emission
   is
      Signal : constant Signal_Emission := Build_Signal (Session, Event);
      Result : A11y.Results.Result := A11y.Results.Ok;
      Validated_Payload : A11y.Events.State_Event_Payload;
   begin
      if not Signal.Publishable then
         return Signal;
      end if;

      Validated_Payload := A11y.Events.Validate_State_Event_Payload
        (Kind    => Event.Kind,
         Payload => Payload,
         Result  => Result);

      if Result.Status /= A11y.Results.Success then
         return Error (Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Object_Path => Signal.Object_Path,
         Event_Name  => To_Unbounded_String
           ("object:state-changed:"
            & A11y.States.Stable_Name (Validated_Payload.State)),
         Property_Detail => Null_Unbounded_String,
         State_Detail => To_Unbounded_String
           (A11y.States.Stable_Name (Validated_Payload.State)),
         Relation_Detail => Null_Unbounded_String,
         Has_Bounds_Payload => Signal.Has_Bounds_Payload,
         Old_Bounds => Signal.Old_Bounds,
         New_Bounds => Signal.New_Bounds,
         Has_Focus_Payload => Signal.Has_Focus_Payload,
         Old_Focus => Signal.Old_Focus,
         New_Focus => Signal.New_Focus,
         Has_Node_Reference_Payload => Signal.Has_Node_Reference_Payload,
         Old_Reference => Signal.Old_Reference,
         New_Reference => Signal.New_Reference,
         Has_Value_Payload => Signal.Has_Value_Payload,
         Old_Value => Signal.Old_Value,
         New_Value => Signal.New_Value,
         Has_Selection_Payload => Signal.Has_Selection_Payload,
         Selection_Node => Signal.Selection_Node,
         Selection_Has_Node => Signal.Selection_Has_Node,
         Selection_Old_Selected => Signal.Selection_Old_Selected,
         Selection_New_Selected => Signal.Selection_New_Selected,
         Selection_Required => Signal.Selection_Required,
         Has_Live_Region_Payload => Signal.Has_Live_Region_Payload,
         Live_Region_Payload => Signal.Live_Region_Payload,
         Has_Tree_Payload => Signal.Has_Tree_Payload,
         Tree_Payload => Signal.Tree_Payload,
         Has_Table_Payload => Signal.Has_Table_Payload,
         Table_Payload => Signal.Table_Payload,
         Has_Document_Payload => Signal.Has_Document_Payload,
         Document_Payload => Signal.Document_Payload,
         Has_Window_Payload => Signal.Has_Window_Payload,
         Window_Payload => Signal.Window_Payload,
         Sequence    => Signal.Sequence,
         Revision    => Signal.Revision);
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Build_Signal;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.Relation_Event_Payload)
      return Signal_Emission
   is
      Signal : constant Signal_Emission := Build_Signal (Session, Event);
      Result : A11y.Results.Result;
      Validated : A11y.Events.Relation_Event_Payload;
   begin
      if not Signal.Publishable then
         return Signal;
      end if;

      Validated := A11y.Events.Validate_Relation_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Object_Path => Signal.Object_Path,
         Event_Name  => Signal.Event_Name,
         Property_Detail => Null_Unbounded_String,
         State_Detail => Null_Unbounded_String,
         Relation_Detail => To_Unbounded_String
           (A11y.Relations.Stable_Name (Validated.Relation)),
         Has_Bounds_Payload => Signal.Has_Bounds_Payload,
         Old_Bounds => Signal.Old_Bounds,
         New_Bounds => Signal.New_Bounds,
         Has_Focus_Payload => Signal.Has_Focus_Payload,
         Old_Focus => Signal.Old_Focus,
         New_Focus => Signal.New_Focus,
         Has_Node_Reference_Payload => Signal.Has_Node_Reference_Payload,
         Old_Reference => Signal.Old_Reference,
         New_Reference => Signal.New_Reference,
         Has_Value_Payload => Signal.Has_Value_Payload,
         Old_Value => Signal.Old_Value,
         New_Value => Signal.New_Value,
         Has_Selection_Payload => Signal.Has_Selection_Payload,
         Selection_Node => Signal.Selection_Node,
         Selection_Has_Node => Signal.Selection_Has_Node,
         Selection_Old_Selected => Signal.Selection_Old_Selected,
         Selection_New_Selected => Signal.Selection_New_Selected,
         Selection_Required => Signal.Selection_Required,
         Has_Live_Region_Payload => Signal.Has_Live_Region_Payload,
         Live_Region_Payload => Signal.Live_Region_Payload,
         Has_Tree_Payload => Signal.Has_Tree_Payload,
         Tree_Payload => Signal.Tree_Payload,
         Has_Table_Payload => Signal.Has_Table_Payload,
         Table_Payload => Signal.Table_Payload,
         Has_Document_Payload => Signal.Has_Document_Payload,
         Document_Payload => Signal.Document_Payload,
         Has_Window_Payload => Signal.Has_Window_Payload,
         Window_Payload => Signal.Window_Payload,
         Sequence    => Signal.Sequence,
         Revision    => Signal.Revision);
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Build_Signal;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.Bounds_Event_Payload)
      return Signal_Emission
   is
      Signal : constant Signal_Emission := Build_Signal (Session, Event);
      Result : A11y.Results.Result;
      Validated : A11y.Events.Bounds_Event_Payload;
   begin
      if not Signal.Publishable then
         return Signal;
      end if;

      Validated := A11y.Events.Validate_Bounds_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Object_Path => Signal.Object_Path,
         Event_Name  => Signal.Event_Name,
         Property_Detail => Null_Unbounded_String,
         State_Detail => Null_Unbounded_String,
         Relation_Detail => Null_Unbounded_String,
         Has_Bounds_Payload => True,
         Old_Bounds => Validated.Old_Bounds,
         New_Bounds => Validated.New_Bounds,
         Has_Focus_Payload => Signal.Has_Focus_Payload,
         Old_Focus => Signal.Old_Focus,
         New_Focus => Signal.New_Focus,
         Has_Node_Reference_Payload => Signal.Has_Node_Reference_Payload,
         Old_Reference => Signal.Old_Reference,
         New_Reference => Signal.New_Reference,
         Has_Value_Payload => Signal.Has_Value_Payload,
         Old_Value => Signal.Old_Value,
         New_Value => Signal.New_Value,
         Has_Selection_Payload => Signal.Has_Selection_Payload,
         Selection_Node => Signal.Selection_Node,
         Selection_Has_Node => Signal.Selection_Has_Node,
         Selection_Old_Selected => Signal.Selection_Old_Selected,
         Selection_New_Selected => Signal.Selection_New_Selected,
         Selection_Required => Signal.Selection_Required,
         Has_Live_Region_Payload => Signal.Has_Live_Region_Payload,
         Live_Region_Payload => Signal.Live_Region_Payload,
         Has_Tree_Payload => Signal.Has_Tree_Payload,
         Tree_Payload => Signal.Tree_Payload,
         Has_Table_Payload => Signal.Has_Table_Payload,
         Table_Payload => Signal.Table_Payload,
         Has_Document_Payload => Signal.Has_Document_Payload,
         Document_Payload => Signal.Document_Payload,
         Has_Window_Payload => Signal.Has_Window_Payload,
         Window_Payload => Signal.Window_Payload,
         Sequence    => Signal.Sequence,
         Revision    => Signal.Revision);
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Build_Signal;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.Focus_Event_Payload)
      return Signal_Emission
   is
      Signal : constant Signal_Emission := Build_Signal (Session, Event);
      Result : A11y.Results.Result;
      Validated : A11y.Events.Focus_Event_Payload;
   begin
      if not Signal.Publishable then
         return Signal;
      end if;

      Validated := A11y.Events.Validate_Focus_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Object_Path => Signal.Object_Path,
         Event_Name  => To_Unbounded_String ("object:state-changed:focused"),
         Property_Detail => Null_Unbounded_String,
         State_Detail => To_Unbounded_String ("focused"),
         Relation_Detail => Null_Unbounded_String,
         Has_Bounds_Payload => Signal.Has_Bounds_Payload,
         Old_Bounds => Signal.Old_Bounds,
         New_Bounds => Signal.New_Bounds,
         Has_Focus_Payload => True,
         Old_Focus => Validated.Old_Focus,
         New_Focus => Validated.New_Focus,
         Has_Node_Reference_Payload => Signal.Has_Node_Reference_Payload,
         Old_Reference => Signal.Old_Reference,
         New_Reference => Signal.New_Reference,
         Has_Value_Payload => Signal.Has_Value_Payload,
         Old_Value => Signal.Old_Value,
         New_Value => Signal.New_Value,
         Has_Selection_Payload => Signal.Has_Selection_Payload,
         Selection_Node => Signal.Selection_Node,
         Selection_Has_Node => Signal.Selection_Has_Node,
         Selection_Old_Selected => Signal.Selection_Old_Selected,
         Selection_New_Selected => Signal.Selection_New_Selected,
         Selection_Required => Signal.Selection_Required,
         Has_Live_Region_Payload => Signal.Has_Live_Region_Payload,
         Live_Region_Payload => Signal.Live_Region_Payload,
         Has_Tree_Payload => Signal.Has_Tree_Payload,
         Tree_Payload => Signal.Tree_Payload,
         Has_Table_Payload => Signal.Has_Table_Payload,
         Table_Payload => Signal.Table_Payload,
         Has_Document_Payload => Signal.Has_Document_Payload,
         Document_Payload => Signal.Document_Payload,
         Has_Window_Payload => Signal.Has_Window_Payload,
         Window_Payload => Signal.Window_Payload,
         Sequence    => Signal.Sequence,
         Revision    => Signal.Revision);
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Build_Signal;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.Node_Reference_Event_Payload)
      return Signal_Emission
   is
      Signal : constant Signal_Emission := Build_Signal (Session, Event);
      Result : A11y.Results.Result;
      Validated : A11y.Events.Node_Reference_Event_Payload;
   begin
      if not Signal.Publishable then
         return Signal;
      end if;

      Validated := A11y.Events.Validate_Node_Reference_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Object_Path => Signal.Object_Path,
         Event_Name  => Signal.Event_Name,
         Property_Detail => Signal.Property_Detail,
         State_Detail => Signal.State_Detail,
         Relation_Detail => Signal.Relation_Detail,
         Has_Bounds_Payload => Signal.Has_Bounds_Payload,
         Old_Bounds => Signal.Old_Bounds,
         New_Bounds => Signal.New_Bounds,
         Has_Focus_Payload => Signal.Has_Focus_Payload,
         Old_Focus => Signal.Old_Focus,
         New_Focus => Signal.New_Focus,
         Has_Node_Reference_Payload => True,
         Old_Reference => Validated.Old_Node,
         New_Reference => Validated.New_Node,
         Has_Value_Payload => Signal.Has_Value_Payload,
         Old_Value => Signal.Old_Value,
         New_Value => Signal.New_Value,
         Has_Selection_Payload => Signal.Has_Selection_Payload,
         Selection_Node => Signal.Selection_Node,
         Selection_Has_Node => Signal.Selection_Has_Node,
         Selection_Old_Selected => Signal.Selection_Old_Selected,
         Selection_New_Selected => Signal.Selection_New_Selected,
         Selection_Required => Signal.Selection_Required,
         Has_Live_Region_Payload => Signal.Has_Live_Region_Payload,
         Live_Region_Payload => Signal.Live_Region_Payload,
         Has_Tree_Payload => Signal.Has_Tree_Payload,
         Tree_Payload => Signal.Tree_Payload,
         Has_Table_Payload => Signal.Has_Table_Payload,
         Table_Payload => Signal.Table_Payload,
         Has_Document_Payload => Signal.Has_Document_Payload,
         Document_Payload => Signal.Document_Payload,
         Has_Window_Payload => Signal.Has_Window_Payload,
         Window_Payload => Signal.Window_Payload,
         Sequence    => Signal.Sequence,
         Revision    => Signal.Revision);
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Build_Signal;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.Value_Event_Payload)
      return Signal_Emission
   is
      Signal : constant Signal_Emission := Build_Signal (Session, Event);
      Result : A11y.Results.Result := A11y.Results.Ok;
      Validated_Payload : A11y.Events.Value_Event_Payload;
   begin
      if not Signal.Publishable then
         return Signal;
      end if;

      Validated_Payload := A11y.Events.Validate_Value_Event_Payload
        (Kind    => Event.Kind,
         Payload => Payload,
         Result  => Result);

      if Result.Status /= A11y.Results.Success then
         return Error (Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Object_Path => Signal.Object_Path,
         Event_Name  => Signal.Event_Name,
         Property_Detail => To_Unbounded_String ("accessible-value"),
         State_Detail => Signal.State_Detail,
         Relation_Detail => Signal.Relation_Detail,
         Has_Bounds_Payload => Signal.Has_Bounds_Payload,
         Old_Bounds => Signal.Old_Bounds,
         New_Bounds => Signal.New_Bounds,
         Has_Focus_Payload => Signal.Has_Focus_Payload,
         Old_Focus => Signal.Old_Focus,
         New_Focus => Signal.New_Focus,
         Has_Node_Reference_Payload => Signal.Has_Node_Reference_Payload,
         Old_Reference => Signal.Old_Reference,
         New_Reference => Signal.New_Reference,
         Has_Value_Payload => True,
         Old_Value => Validated_Payload.Old_Value,
         New_Value => Validated_Payload.New_Value,
         Has_Selection_Payload => Signal.Has_Selection_Payload,
         Selection_Node => Signal.Selection_Node,
         Selection_Has_Node => Signal.Selection_Has_Node,
         Selection_Old_Selected => Signal.Selection_Old_Selected,
         Selection_New_Selected => Signal.Selection_New_Selected,
         Selection_Required => Signal.Selection_Required,
         Has_Live_Region_Payload => Signal.Has_Live_Region_Payload,
         Live_Region_Payload => Signal.Live_Region_Payload,
         Has_Tree_Payload => Signal.Has_Tree_Payload,
         Tree_Payload => Signal.Tree_Payload,
         Has_Table_Payload => Signal.Has_Table_Payload,
         Table_Payload => Signal.Table_Payload,
         Has_Document_Payload => Signal.Has_Document_Payload,
         Document_Payload => Signal.Document_Payload,
         Has_Window_Payload => Signal.Has_Window_Payload,
         Window_Payload => Signal.Window_Payload,
         Sequence    => Signal.Sequence,
         Revision    => Signal.Revision);
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Build_Signal;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.Selection_Event_Payload)
      return Signal_Emission
   is
      Signal : constant Signal_Emission := Build_Signal (Session, Event);
      Result : A11y.Results.Result;
      Validated : A11y.Events.Selection_Event_Payload;
   begin
      if not Signal.Publishable then
         return Signal;
      end if;

      Validated := A11y.Events.Validate_Selection_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Object_Path => Signal.Object_Path,
         Event_Name  => Signal.Event_Name,
         Property_Detail => Signal.Property_Detail,
         State_Detail => Signal.State_Detail,
         Relation_Detail => Signal.Relation_Detail,
         Has_Bounds_Payload => Signal.Has_Bounds_Payload,
         Old_Bounds => Signal.Old_Bounds,
         New_Bounds => Signal.New_Bounds,
         Has_Focus_Payload => Signal.Has_Focus_Payload,
         Old_Focus => Signal.Old_Focus,
         New_Focus => Signal.New_Focus,
         Has_Node_Reference_Payload => Signal.Has_Node_Reference_Payload,
         Old_Reference => Signal.Old_Reference,
         New_Reference => Signal.New_Reference,
         Has_Value_Payload => Signal.Has_Value_Payload,
         Old_Value => Signal.Old_Value,
         New_Value => Signal.New_Value,
         Has_Selection_Payload => True,
         Selection_Node => Validated.Changed_Node,
         Selection_Has_Node => Validated.Has_Changed_Node,
         Selection_Old_Selected => Validated.Old_Selected,
         Selection_New_Selected => Validated.New_Selected,
         Selection_Required => Validated.Requires_Selection,
         Has_Live_Region_Payload => Signal.Has_Live_Region_Payload,
         Live_Region_Payload => Signal.Live_Region_Payload,
         Has_Tree_Payload => Signal.Has_Tree_Payload,
         Tree_Payload => Signal.Tree_Payload,
         Has_Table_Payload => Signal.Has_Table_Payload,
         Table_Payload => Signal.Table_Payload,
         Has_Document_Payload => Signal.Has_Document_Payload,
         Document_Payload => Signal.Document_Payload,
         Has_Window_Payload => Signal.Has_Window_Payload,
         Window_Payload => Signal.Window_Payload,
         Sequence    => Signal.Sequence,
         Revision    => Signal.Revision);
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Build_Signal;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.Live_Region_Event_Payload)
      return Signal_Emission
   is
      Signal : constant Signal_Emission := Build_Signal (Session, Event);
      Result : A11y.Results.Result;
      Validated : A11y.Events.Live_Region_Event_Payload;
   begin
      if not Signal.Publishable then
         return Signal;
      end if;

      Validated := A11y.Events.Validate_Live_Region_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Object_Path => Signal.Object_Path,
         Event_Name  => Signal.Event_Name,
         Property_Detail =>
           To_Unbounded_String
             ((if Event.Kind = A11y.Events.Announcement_Requested
               then "announcement"
               else "live-region")),
         State_Detail => Signal.State_Detail,
         Relation_Detail => Signal.Relation_Detail,
         Has_Bounds_Payload => Signal.Has_Bounds_Payload,
         Old_Bounds => Signal.Old_Bounds,
         New_Bounds => Signal.New_Bounds,
         Has_Focus_Payload => Signal.Has_Focus_Payload,
         Old_Focus => Signal.Old_Focus,
         New_Focus => Signal.New_Focus,
         Has_Node_Reference_Payload => Signal.Has_Node_Reference_Payload,
         Old_Reference => Signal.Old_Reference,
         New_Reference => Signal.New_Reference,
         Has_Value_Payload => Signal.Has_Value_Payload,
         Old_Value => Signal.Old_Value,
         New_Value => Signal.New_Value,
         Has_Selection_Payload => Signal.Has_Selection_Payload,
         Selection_Node => Signal.Selection_Node,
         Selection_Has_Node => Signal.Selection_Has_Node,
         Selection_Old_Selected => Signal.Selection_Old_Selected,
         Selection_New_Selected => Signal.Selection_New_Selected,
         Selection_Required => Signal.Selection_Required,
         Has_Live_Region_Payload => True,
         Live_Region_Payload => Validated,
         Has_Tree_Payload => Signal.Has_Tree_Payload,
         Tree_Payload => Signal.Tree_Payload,
         Has_Table_Payload => Signal.Has_Table_Payload,
         Table_Payload => Signal.Table_Payload,
         Has_Document_Payload => Signal.Has_Document_Payload,
         Document_Payload => Signal.Document_Payload,
         Has_Window_Payload => Signal.Has_Window_Payload,
         Window_Payload => Signal.Window_Payload,
         Sequence    => Signal.Sequence,
         Revision    => Signal.Revision);
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Build_Signal;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.Tree_Event_Payload)
      return Signal_Emission
   is
      Signal : constant Signal_Emission := Build_Signal (Session, Event);
      Result : A11y.Results.Result;
      Validated : A11y.Events.Tree_Event_Payload;
   begin
      if not Signal.Publishable then
         return Signal;
      end if;

      Validated := A11y.Events.Validate_Tree_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Object_Path => Signal.Object_Path,
         Event_Name  => Signal.Event_Name,
         Property_Detail => Signal.Property_Detail,
         State_Detail => Signal.State_Detail,
         Relation_Detail => Signal.Relation_Detail,
         Has_Bounds_Payload => Signal.Has_Bounds_Payload,
         Old_Bounds => Signal.Old_Bounds,
         New_Bounds => Signal.New_Bounds,
         Has_Focus_Payload => Signal.Has_Focus_Payload,
         Old_Focus => Signal.Old_Focus,
         New_Focus => Signal.New_Focus,
         Has_Node_Reference_Payload => Signal.Has_Node_Reference_Payload,
         Old_Reference => Signal.Old_Reference,
         New_Reference => Signal.New_Reference,
         Has_Value_Payload => Signal.Has_Value_Payload,
         Old_Value => Signal.Old_Value,
         New_Value => Signal.New_Value,
         Has_Selection_Payload => Signal.Has_Selection_Payload,
         Selection_Node => Signal.Selection_Node,
         Selection_Has_Node => Signal.Selection_Has_Node,
         Selection_Old_Selected => Signal.Selection_Old_Selected,
         Selection_New_Selected => Signal.Selection_New_Selected,
         Selection_Required => Signal.Selection_Required,
         Has_Live_Region_Payload => Signal.Has_Live_Region_Payload,
         Live_Region_Payload => Signal.Live_Region_Payload,
         Has_Tree_Payload => True,
         Tree_Payload => Validated,
         Has_Table_Payload => Signal.Has_Table_Payload,
         Table_Payload => Signal.Table_Payload,
         Has_Document_Payload => Signal.Has_Document_Payload,
         Document_Payload => Signal.Document_Payload,
         Has_Window_Payload => Signal.Has_Window_Payload,
         Window_Payload => Signal.Window_Payload,
         Sequence    => Signal.Sequence,
         Revision    => Signal.Revision);
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Build_Signal;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.Table_Event_Payload)
      return Signal_Emission
   is
      Signal : constant Signal_Emission := Build_Signal (Session, Event);
      Result : A11y.Results.Result;
      Validated : A11y.Events.Table_Event_Payload;
   begin
      if not Signal.Publishable then
         return Signal;
      end if;

      Validated := A11y.Events.Validate_Table_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Object_Path => Signal.Object_Path,
         Event_Name  => Signal.Event_Name,
         Property_Detail => Signal.Property_Detail,
         State_Detail => Signal.State_Detail,
         Relation_Detail => Signal.Relation_Detail,
         Has_Bounds_Payload => Signal.Has_Bounds_Payload,
         Old_Bounds => Signal.Old_Bounds,
         New_Bounds => Signal.New_Bounds,
         Has_Focus_Payload => Signal.Has_Focus_Payload,
         Old_Focus => Signal.Old_Focus,
         New_Focus => Signal.New_Focus,
         Has_Node_Reference_Payload => Signal.Has_Node_Reference_Payload,
         Old_Reference => Signal.Old_Reference,
         New_Reference => Signal.New_Reference,
         Has_Value_Payload => Signal.Has_Value_Payload,
         Old_Value => Signal.Old_Value,
         New_Value => Signal.New_Value,
         Has_Selection_Payload => Signal.Has_Selection_Payload,
         Selection_Node => Signal.Selection_Node,
         Selection_Has_Node => Signal.Selection_Has_Node,
         Selection_Old_Selected => Signal.Selection_Old_Selected,
         Selection_New_Selected => Signal.Selection_New_Selected,
         Selection_Required => Signal.Selection_Required,
         Has_Live_Region_Payload => Signal.Has_Live_Region_Payload,
         Live_Region_Payload => Signal.Live_Region_Payload,
         Has_Tree_Payload => Signal.Has_Tree_Payload,
         Tree_Payload => Signal.Tree_Payload,
         Has_Table_Payload => True,
         Table_Payload => Validated,
         Has_Document_Payload => Signal.Has_Document_Payload,
         Document_Payload => Signal.Document_Payload,
         Has_Window_Payload => Signal.Has_Window_Payload,
         Window_Payload => Signal.Window_Payload,
         Sequence    => Signal.Sequence,
         Revision    => Signal.Revision);
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Build_Signal;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.Document_Event_Payload)
      return Signal_Emission
   is
      Signal : constant Signal_Emission := Build_Signal (Session, Event);
      Result : A11y.Results.Result;
      Validated : A11y.Events.Document_Event_Payload;
   begin
      if not Signal.Publishable then
         return Signal;
      end if;

      Validated := A11y.Events.Validate_Document_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Object_Path => Signal.Object_Path,
         Event_Name  => Signal.Event_Name,
         Property_Detail => Signal.Property_Detail,
         State_Detail => Signal.State_Detail,
         Relation_Detail => Signal.Relation_Detail,
         Has_Bounds_Payload => Signal.Has_Bounds_Payload,
         Old_Bounds => Signal.Old_Bounds,
         New_Bounds => Signal.New_Bounds,
         Has_Focus_Payload => Signal.Has_Focus_Payload,
         Old_Focus => Signal.Old_Focus,
         New_Focus => Signal.New_Focus,
         Has_Node_Reference_Payload => Signal.Has_Node_Reference_Payload,
         Old_Reference => Signal.Old_Reference,
         New_Reference => Signal.New_Reference,
         Has_Value_Payload => Signal.Has_Value_Payload,
         Old_Value => Signal.Old_Value,
         New_Value => Signal.New_Value,
         Has_Selection_Payload => Signal.Has_Selection_Payload,
         Selection_Node => Signal.Selection_Node,
         Selection_Has_Node => Signal.Selection_Has_Node,
         Selection_Old_Selected => Signal.Selection_Old_Selected,
         Selection_New_Selected => Signal.Selection_New_Selected,
         Selection_Required => Signal.Selection_Required,
         Has_Live_Region_Payload => Signal.Has_Live_Region_Payload,
         Live_Region_Payload => Signal.Live_Region_Payload,
         Has_Tree_Payload => Signal.Has_Tree_Payload,
         Tree_Payload => Signal.Tree_Payload,
         Has_Table_Payload => Signal.Has_Table_Payload,
         Table_Payload => Signal.Table_Payload,
         Has_Document_Payload => True,
         Document_Payload => Validated,
         Has_Window_Payload => Signal.Has_Window_Payload,
         Window_Payload => Signal.Window_Payload,
         Sequence    => Signal.Sequence,
         Revision    => Signal.Revision);
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Build_Signal;

   function Build_Signal
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Event   : A11y.Events.Event;
      Payload : A11y.Events.Window_Event_Payload)
      return Signal_Emission
   is
      Signal : constant Signal_Emission := Build_Signal (Session, Event);
      Result : A11y.Results.Result;
      Validated : A11y.Events.Window_Event_Payload;
   begin
      if not Signal.Publishable then
         return Signal;
      end if;

      Validated := A11y.Events.Validate_Window_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Object_Path => Signal.Object_Path,
         Event_Name  => Signal.Event_Name,
         Property_Detail => Signal.Property_Detail,
         State_Detail => Signal.State_Detail,
         Relation_Detail => Signal.Relation_Detail,
         Has_Bounds_Payload => Signal.Has_Bounds_Payload,
         Old_Bounds => Signal.Old_Bounds,
         New_Bounds => Signal.New_Bounds,
         Has_Focus_Payload => Signal.Has_Focus_Payload,
         Old_Focus => Signal.Old_Focus,
         New_Focus => Signal.New_Focus,
         Has_Node_Reference_Payload => Signal.Has_Node_Reference_Payload,
         Old_Reference => Signal.Old_Reference,
         New_Reference => Signal.New_Reference,
         Has_Value_Payload => Signal.Has_Value_Payload,
         Old_Value => Signal.Old_Value,
         New_Value => Signal.New_Value,
         Has_Selection_Payload => Signal.Has_Selection_Payload,
         Selection_Node => Signal.Selection_Node,
         Selection_Has_Node => Signal.Selection_Has_Node,
         Selection_Old_Selected => Signal.Selection_Old_Selected,
         Selection_New_Selected => Signal.Selection_New_Selected,
         Selection_Required => Signal.Selection_Required,
         Has_Live_Region_Payload => Signal.Has_Live_Region_Payload,
         Live_Region_Payload => Signal.Live_Region_Payload,
         Has_Tree_Payload => Signal.Has_Tree_Payload,
         Tree_Payload => Signal.Tree_Payload,
         Has_Table_Payload => Signal.Has_Table_Payload,
         Table_Payload => Signal.Table_Payload,
         Has_Document_Payload => Signal.Has_Document_Payload,
         Document_Payload => Signal.Document_Payload,
         Has_Window_Payload => True,
         Window_Payload => Validated,
         Sequence    => Signal.Sequence,
         Revision    => Signal.Revision);
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Build_Signal;

end A11y.Linux.ATSPi_Signals;
