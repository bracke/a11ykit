with A11y.Events;
with A11y.Node_Ids;
with A11y.Results;
with A11y.Sessions;

package A11y.Backends.Event_Pumps is

   type Pump_One_Report is record
      Before_Pending : Natural := 0;
      After_Pending  : Natural := 0;
      Capacity       : Natural := 0;
      Has_Event      : Boolean := False;
      Event_Sequence : A11y.Event_Sequence := A11y.No_Event;
      Event_Source   : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Event_Kind     : A11y.Events.Event_Kind := A11y.Events.Node_Created;
      Event_Validated : Boolean := False;
      Published       : Boolean := False;
      Acknowledged    : Boolean := False;
      Delivered       : Natural := 0;
      Peek_Status        : A11y.Results.Status_Code := A11y.Results.Success;
      Validation_Status  : A11y.Results.Status_Code := A11y.Results.Success;
      Publish_Status     : A11y.Results.Status_Code := A11y.Results.Success;
      Acknowledge_Status : A11y.Results.Status_Code := A11y.Results.Success;
      Status             : A11y.Results.Status_Code := A11y.Results.Success;
   end record;

   type Pump_Stop_Reason is
     (Pump_Drained,
      Pump_Failed,
      Pump_Bounded);

   type Pump_All_Report is record
      Before_Pending : Natural := 0;
      After_Pending  : Natural := 0;
      Capacity       : Natural := 0;
      Attempted      : Natural := 0;
      Delivered      : Natural := 0;
      Last_Event_Sequence : A11y.Event_Sequence := A11y.No_Event;
      Stop_Reason    : Pump_Stop_Reason := Pump_Drained;
      Status         : A11y.Results.Status_Code := A11y.Results.Success;
   end record;

   procedure Pump_One
     (Session : in out A11y.Sessions.Semantic_Session;
      Backend : in out A11y.Backends.Backend'Class;
      Event   : out A11y.Events.Event;
      Result  : out A11y.Results.Result);

   procedure Pump_One_With_Report
     (Session : in out A11y.Sessions.Semantic_Session;
      Backend : in out A11y.Backends.Backend'Class;
      Event   : out A11y.Events.Event;
      Report  : out Pump_One_Report;
      Result  : out A11y.Results.Result);

   procedure Pump_All
     (Session   : in out A11y.Sessions.Semantic_Session;
      Backend   : in out A11y.Backends.Backend'Class;
      Delivered : out Natural;
      Result    : out A11y.Results.Result);

   procedure Pump_All_With_Report
     (Session   : in out A11y.Sessions.Semantic_Session;
      Backend   : in out A11y.Backends.Backend'Class;
      Report    : out Pump_All_Report;
      Result    : out A11y.Results.Result);

end A11y.Backends.Event_Pumps;
