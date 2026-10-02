package A11y_Fixture_Application is
   Schema : constant String := "org.a11y.fixture_application.v1";

   function Command_Result_Count return Natural;
   function Readiness_Line return String;
   function Results_Text return String;
   function ATSPi_Startup_JSON
     (Address : String;
      User_Id : Natural)
      return String;
   function ATSPi_Environment_Startup_JSON
     (Value   : String;
      User_Id : Natural)
      return String;
   function ATSPi_Host_Environment_Startup_JSON
     (User_Id : Natural)
      return String;
   function ATSPi_Serve_JSON
     (Address        : String;
      User_Id        : Natural;
      Max_Iterations : Natural)
      return String;
   function ATSPi_Serve_JSON
     (Address         : String;
      User_Id         : Natural;
      Max_Iterations  : Natural;
      Read_Timeout_MS : Natural)
      return String;
   function ATSPi_Host_Environment_Serve_JSON
     (User_Id        : Natural;
      Max_Iterations : Natural)
      return String;
   function ATSPi_Host_Environment_Serve_JSON
     (User_Id         : Natural;
      Max_Iterations  : Natural;
      Read_Timeout_MS : Natural)
      return String;
   function JSON return String;
end A11y_Fixture_Application;
