with Ada.Calendar;

package body A11y.Backends.Event_Pumps is

   procedure Pump_One
     (Session : in out A11y.Sessions.Semantic_Session;
      Backend : in out A11y.Backends.Backend'Class;
      Event   : out A11y.Events.Event;
      Result  : out A11y.Results.Result)
   is
      Report : Pump_One_Report;
   begin
      Pump_One_With_Report (Session, Backend, Event, Report, Result);
   end Pump_One;

   procedure Pump_One_With_Report
     (Session : in out A11y.Sessions.Semantic_Session;
      Backend : in out A11y.Backends.Backend'Class;
      Event   : out A11y.Events.Event;
      Report  : out Pump_One_Report;
      Result  : out A11y.Results.Result)
   is
      Publish_Result : A11y.Results.Result;
      Acknowledge_Result : A11y.Results.Result;
   begin
      Event :=
        (Sequence  => A11y.No_Event,
         Timestamp => Ada.Calendar.Clock,
         Source    => A11y.Node_Ids.No_Node,
         Kind      => A11y.Events.Node_Created,
         Revision  => A11y.Initial_Revision);
      Report :=
        (Before_Pending => A11y.Sessions.Pending_Event_Count (Session),
         After_Pending  => A11y.Sessions.Pending_Event_Count (Session),
         Capacity       => A11y.Sessions.Event_Capacity (Session),
         Has_Event      => False,
         Event_Sequence => A11y.No_Event,
         Event_Source   => A11y.Node_Ids.No_Node,
         Event_Kind     => A11y.Events.Node_Created,
         Event_Validated => False,
         Published       => False,
         Acknowledged    => False,
         Delivered       => 0,
         Peek_Status        => A11y.Results.Success,
         Validation_Status  => A11y.Results.Success,
         Publish_Status     => A11y.Results.Success,
         Acknowledge_Status => A11y.Results.Success,
         Status             => A11y.Results.Success);

      A11y.Sessions.Peek_Event (Session, Event, Result);
      Report.Peek_Status := Result.Status;
      if A11y.Results.Failed (Result) then
         Report.After_Pending := A11y.Sessions.Pending_Event_Count (Session);
         Report.Status := Result.Status;
         return;
      end if;
      Report.Has_Event := True;
      Report.Event_Sequence := Event.Sequence;
      Report.Event_Source := Event.Source;
      Report.Event_Kind := Event.Kind;

      Result := A11y.Events.Validate_Event (Event);
      Report.Validation_Status := Result.Status;
      if A11y.Results.Failed (Result) then
         Report.After_Pending := A11y.Sessions.Pending_Event_Count (Session);
         Report.Status := Result.Status;
         return;
      end if;
      Report.Event_Validated := True;

      Publish_Result := Backend.Publish (Event);
      Report.Publish_Status := Publish_Result.Status;
      if A11y.Results.Failed (Publish_Result) then
         Result := Publish_Result;
         Report.After_Pending := A11y.Sessions.Pending_Event_Count (Session);
         Report.Status := Result.Status;
         return;
      end if;
      Report.Published := True;

      A11y.Sessions.Acknowledge_Event
        (Session, Event.Sequence, Acknowledge_Result);
      Report.Acknowledge_Status := Acknowledge_Result.Status;
      Result := Acknowledge_Result;
      if A11y.Results.Succeeded (Result) then
         Report.Acknowledged := True;
         Report.Delivered := 1;
      end if;
      Report.After_Pending := A11y.Sessions.Pending_Event_Count (Session);
      Report.Status := Result.Status;
   exception
      when others =>
         Report :=
           (Before_Pending => 0,
            After_Pending  => A11y.Sessions.Pending_Event_Count (Session),
            Capacity       => A11y.Sessions.Event_Capacity (Session),
            Has_Event      => False,
            Event_Sequence => A11y.No_Event,
            Event_Source   => A11y.Node_Ids.No_Node,
            Event_Kind     => A11y.Events.Node_Created,
            Event_Validated => False,
            Published       => False,
            Acknowledged    => False,
            Delivered       => 0,
            Peek_Status        => A11y.Results.Internal_Error,
            Validation_Status  => A11y.Results.Internal_Error,
            Publish_Status     => A11y.Results.Internal_Error,
            Acknowledge_Status => A11y.Results.Internal_Error,
            Status             => A11y.Results.Internal_Error);
         Result := (Status => A11y.Results.Internal_Error);
   end Pump_One_With_Report;

   procedure Pump_All
     (Session   : in out A11y.Sessions.Semantic_Session;
      Backend   : in out A11y.Backends.Backend'Class;
      Delivered : out Natural;
      Result    : out A11y.Results.Result)
   is
      Report : Pump_All_Report;
   begin
      Pump_All_With_Report (Session, Backend, Report, Result);
      Delivered := Report.Delivered;
   end Pump_All;

   procedure Pump_All_With_Report
     (Session   : in out A11y.Sessions.Semantic_Session;
      Backend   : in out A11y.Backends.Backend'Class;
      Report    : out Pump_All_Report;
      Result    : out A11y.Results.Result)
   is
      Event : A11y.Events.Event;
      One : Pump_One_Report;
   begin
      Report :=
        (Before_Pending => A11y.Sessions.Pending_Event_Count (Session),
         After_Pending  => A11y.Sessions.Pending_Event_Count (Session),
         Capacity       => A11y.Sessions.Event_Capacity (Session),
         Attempted      => 0,
         Delivered      => 0,
         Last_Event_Sequence => A11y.No_Event,
         Stop_Reason    => Pump_Drained,
         Status         => A11y.Results.Success);

      while A11y.Sessions.Pending_Event_Count (Session) > 0 loop
         if Report.Attempted >= A11y.Sessions.Event_Capacity (Session) then
            Result := (Status => A11y.Results.Resource_Limit);
            Report.After_Pending := A11y.Sessions.Pending_Event_Count (Session);
            Report.Stop_Reason := Pump_Bounded;
            Report.Status := Result.Status;
            return;
         end if;

         Report.Attempted := Report.Attempted + 1;
         Pump_One_With_Report (Session, Backend, Event, One, Result);
         if One.Has_Event then
            Report.Last_Event_Sequence := One.Event_Sequence;
         end if;
         if A11y.Results.Failed (Result) then
            Report.After_Pending := A11y.Sessions.Pending_Event_Count (Session);
            Report.Stop_Reason := Pump_Failed;
            Report.Status := Result.Status;
            return;
         end if;

         Report.Delivered := Report.Delivered + One.Delivered;
      end loop;

      Report.After_Pending := A11y.Sessions.Pending_Event_Count (Session);
      Report.Stop_Reason := Pump_Drained;
      Report.Status := A11y.Results.Success;
      Result := A11y.Results.Ok;
   exception
      when others =>
         Report :=
           (Before_Pending => 0,
            After_Pending  => A11y.Sessions.Pending_Event_Count (Session),
            Capacity       => A11y.Sessions.Event_Capacity (Session),
            Attempted      => 0,
            Delivered      => 0,
            Last_Event_Sequence => A11y.No_Event,
            Stop_Reason    => Pump_Failed,
            Status         => A11y.Results.Internal_Error);
         Result := (Status => A11y.Results.Internal_Error);
   end Pump_All_With_Report;

end A11y.Backends.Event_Pumps;
