package A11y_Native_Observation_Report is
   Schema : constant String := "org.a11y.native_observation.v1";

   type Readiness_Status is
     (Blocked_Transport_Unavailable,
      Incomplete_Native_Evidence,
      Native_Conformance_Ready);

   function Client_Count return Natural;
   function All_Clients_Blocked return Boolean;
   function Readiness return Readiness_Status;
   function Readiness_Name return String;
   function Is_Native_Conformance_Ready return Boolean;
   function Markdown return String;
   function JSON return String;
   function Summary_JSON return String;
end A11y_Native_Observation_Report;
