with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;

with A11y.Backends.Native_Backends;
with A11y.Linux.ATSPi_Backend_Sessions;
with A11y.Linux.ATSPi_Bus;
with A11y.Linux.ATSPi_DBus_Boundary;
with A11y.Linux.ATSPi_Method_Router;
with A11y.Linux.ATSPi_Objects;
with A11y.Linux.ATSPi_Scheduler;
with A11y.Linux.ATSPi_Startup;
with A11y.Linux.DBus_Auth;
with A11y.Linux.DBus_Messages;
with A11y.Node_Ids;
with A11y.Results;
with A11y.Roles;
with A11y_Fixture_Report;
with A11y_Test_Fixtures;

package body A11y_Fixture_Application is
   use Ada.Strings.Unbounded;
   use type A11y.Backends.Native_Backends.Native_Transport_State;
   use type A11y.Linux.ATSPi_DBus_Boundary.DBus_Reply_Kind;
   use type A11y.Linux.ATSPi_Method_Router.Routed_Reply_Kind;
   use type A11y.Linux.ATSPi_Startup.Event_Loop_Operation;
   use type A11y.Results.Status_Code;

   function Q (Value : String) return String is
      Result : Unbounded_String;
   begin
      Append (Result, '"');
      for Ch of Value loop
         if Ch = '"' then
            Append (Result, "\""");
         elsif Ch = '\' then
            Append (Result, "\\");
         elsif Character'Pos (Ch) < 32 then
            Append (Result, ' ');
         else
            Append (Result, Ch);
         end if;
      end loop;
      Append (Result, '"');
      return To_String (Result);
   end Q;

   function Command_Name
     (Kind : A11y_Test_Fixtures.Command_Kind)
      return String is
     (A11y_Test_Fixtures.Command_Kind'Image (Kind));

   function Command_Result_Count return Natural is
     (Natural (A11y_Test_Fixtures.Script.Length));

   function Readiness_Line return String is
     ("A11Y_FIXTURE_READY schema="
      & Schema
      & " nodes="
      & Natural'Image (A11y_Fixture_Report.Node_Count)
      & " commands="
      & Natural'Image (Command_Result_Count));

   function Results_Text return String is
      Result : Unbounded_String;
      Index : Natural := 0;
   begin
      Append (Result, Readiness_Line & ASCII.LF);
      for Command of A11y_Test_Fixtures.Script loop
         Index := Index + 1;
         Append
           (Result,
            "RESULT index="
            & Natural'Image (Index)
            & " command="
            & Command_Name (Command.Kind)
            & " target="
            & A11y.Node_Ids.Image (Command.Target)
            & " status=accepted"
            & ASCII.LF);
      end loop;
      return To_String (Result);
   end Results_Text;

   function Status_Name (Status : A11y.Results.Status_Code) return String is
     (Ada.Strings.Fixed.Trim
        (A11y.Results.Status_Code'Image (Status), Ada.Strings.Both));

   function State_Name
     (State : A11y.Linux.ATSPi_Bus.Connection_State)
      return String is
     (Ada.Strings.Fixed.Trim
        (A11y.Linux.ATSPi_Bus.Connection_State'Image (State),
         Ada.Strings.Both));

   function Transport_Name
     (State : A11y.Backends.Native_Backends.Native_Transport_State)
      return String is
     (A11y.Backends.Native_Backends.Name (State));

   function Operation_Name
     (Operation : A11y.Linux.ATSPi_Startup.Event_Loop_Operation)
      return String is
     (Ada.Strings.Fixed.Trim
        (A11y.Linux.ATSPi_Startup.Event_Loop_Operation'Image (Operation),
         Ada.Strings.Both));

   function Stop_Reason_Name
     (Reason : A11y.Linux.ATSPi_Startup.Pump_Bounded_Stop_Reason)
      return String is
     (Ada.Strings.Fixed.Trim
        (A11y.Linux.ATSPi_Startup.Pump_Bounded_Stop_Reason'Image (Reason),
         Ada.Strings.Both));

   procedure Configure_ATSPi_Root_Snapshot
     (Snapshots : in out A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle) is
   begin
      Snapshots.Accessible.Id := A11y_Test_Fixtures.Application_Id;
      Snapshots.Accessible.Role := A11y.Roles.Application;
      Snapshots.Accessible.Name :=
        To_Unbounded_String ("Fixture Application");
      Snapshots.Accessible.Children.Clear;
      Snapshots.Accessible.Children.Append (A11y_Test_Fixtures.Main_Window_Id);
      Snapshots.Accessible.Child_Count := 1;
      Snapshots.Application.Id := A11y_Test_Fixtures.Application_Id;
      Snapshots.Application.Application_Id :=
        A11y.Node_Ids.To_Natural (A11y_Test_Fixtures.Application_Id);
      Snapshots.Application.Toolkit_Name := To_Unbounded_String ("a11y_tests");
      Snapshots.Application.Version := To_Unbounded_String ("0.1.0-dev");
   end Configure_ATSPi_Root_Snapshot;

   function ATSPi_Startup_JSON_With_Mode
     (Value            : String;
      User_Id          : Natural;
      From_Environment : Boolean;
      From_Host_Environment : Boolean := False)
      return String
   is
      type Session_Access is access
        A11y.Linux.ATSPi_Backend_Sessions.Backend_Session;
      type Snapshot_Bundle_Access is access
        A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Session_Ref : constant Session_Access :=
        new A11y.Linux.ATSPi_Backend_Sessions.Backend_Session;
      Session : A11y.Linux.ATSPi_Backend_Sessions.Backend_Session
      renames Session_Ref.all;
      Snapshots_Ref : constant Snapshot_Bundle_Access :=
        new A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle
      renames Snapshots_Ref.all;
      Result : A11y.Results.Result;
      Stop_Result : A11y.Results.Result;
      Session_View :
        A11y.Linux.ATSPi_Backend_Sessions.Session_Report;
      Startup_Report :
        A11y.Linux.ATSPi_Backend_Sessions.Session_Startup_Report;
      Root_Query_Status : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
      Root_Query_OK : Boolean := False;
      Root_Role : Natural := 0;
      Root_Child_Count_Status : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
      Root_Child_Count_OK : Boolean := False;
      Root_Child_Count : Natural := 0;
      Root_First_Child_Status : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
      Root_First_Child_OK : Boolean := False;
      Root_First_Child : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Started : Boolean := False;
      Final_Status : A11y.Results.Status_Code := A11y.Results.Success;
      Output : Unbounded_String;
   begin
      if From_Host_Environment then
         A11y.Linux.ATSPi_Backend_Sessions
           .Start_From_Host_Environment_With_Report
           (Session,
            A11y.Linux.DBus_Auth.External_User_Id (User_Id),
            A11y_Test_Fixtures.Application_Id,
            Startup_Report,
            Result);
      elsif From_Environment then
         A11y.Linux.ATSPi_Backend_Sessions
           .Start_From_Environment_Value_With_Report
           (Session,
            Value,
            A11y.Linux.DBus_Auth.External_User_Id (User_Id),
            A11y_Test_Fixtures.Application_Id,
            Startup_Report,
            Result);
      else
         A11y.Linux.ATSPi_Backend_Sessions.Start_From_Address_With_Report
           (Session,
            Value,
            A11y.Linux.DBus_Auth.External_User_Id (User_Id),
            A11y_Test_Fixtures.Application_Id,
            Startup_Report,
            Result);
      end if;
      A11y.Linux.ATSPi_Backend_Sessions.Capture_Report
        (Session, Session_View);
      Configure_ATSPi_Root_Snapshot (Snapshots);
      if Session_View.Registered
      then
         declare
            Root_Reply : constant
              A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply :=
                A11y.Linux.ATSPi_Backend_Sessions
                  .Dispatch_Application_Root_Method
                    (Session,
                     A11y.Linux.ATSPi_Objects.Accessible,
                     "GetRole",
                     Snapshots);
         begin
            Root_Query_Status := Root_Reply.Status;
            if Root_Reply.Kind =
                A11y.Linux.ATSPi_DBus_Boundary.Method_Reply
              and then Root_Reply.Routed_Kind =
                A11y.Linux.ATSPi_Method_Router.Accessible_Role
              and then Root_Reply.Status = A11y.Results.Success
            then
               Root_Query_OK := True;
               Root_Role := Root_Reply.UInt32;
            end if;
         end;

         declare
            Child_Count_Reply : constant
              A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply :=
                A11y.Linux.ATSPi_Backend_Sessions
                  .Dispatch_Application_Root_Method
                    (Session,
                     A11y.Linux.ATSPi_Objects.Accessible,
                     "GetChildCount",
                     Snapshots);
         begin
            Root_Child_Count_Status := Child_Count_Reply.Status;
            if Child_Count_Reply.Kind =
                A11y.Linux.ATSPi_DBus_Boundary.Method_Reply
              and then Child_Count_Reply.Routed_Kind =
                A11y.Linux.ATSPi_Method_Router.Accessible_UInt32
              and then Child_Count_Reply.Status = A11y.Results.Success
            then
               Root_Child_Count_OK := True;
               Root_Child_Count := Child_Count_Reply.UInt32;
            end if;
         end;

         declare
            Child_Reply : constant
              A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply :=
                A11y.Linux.ATSPi_Backend_Sessions
                  .Dispatch_Application_Root_Method
                    (Session,
                     A11y.Linux.ATSPi_Objects.Accessible,
                     "GetChildAtIndex",
                     0,
                     Snapshots);
         begin
            Root_First_Child_Status := Child_Reply.Status;
            if Child_Reply.Kind =
                A11y.Linux.ATSPi_DBus_Boundary.Method_Reply
              and then Child_Reply.Routed_Kind =
                A11y.Linux.ATSPi_Method_Router.Accessible_Node
              and then Child_Reply.Status = A11y.Results.Success
            then
               Root_First_Child_OK := True;
               Root_First_Child := Child_Reply.Node;
            end if;
         end;
      end if;
      Started := Session_View.Transport.State =
        A11y.Backends.Native_Backends.Transport_Running;
      Final_Status :=
        (if A11y.Results.Failed (Result)
         then Result.Status
         else Session_View.Transport.Last_Status);

      A11y.Linux.ATSPi_Backend_Sessions.Stop (Session, Stop_Result);
      if A11y.Results.Succeeded ((Status => Final_Status))
        and then A11y.Results.Failed (Stop_Result)
      then
         Final_Status := Stop_Result.Status;
      end if;

      Append (Output, "{" & ASCII.LF);
      Append
        (Output,
         "  ""schema"": "
         & Q ("org.a11y.fixture_atspi_startup.v1")
         & ","
         & ASCII.LF);
      Append (Output, "  ""fixture_schema"": " & Q (Schema) & "," & ASCII.LF);
      Append (Output, "  ""ready"": true," & ASCII.LF);
      Append (Output, "  ""platform"": ""Linux""," & ASCII.LF);
      Append (Output, "  ""native_api"": ""AT-SPI2""," & ASCII.LF);
      Append
        (Output,
         "  ""address_supplied"": "
         & (if From_Host_Environment then "false" else "true")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""host_environment_used"": "
         & (if From_Host_Environment then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_source"": "
         & Q
           (A11y.Linux.ATSPi_Backend_Sessions.Startup_Source_Name
              (Startup_Report.Source))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""host_at_spi_bus_address_present"": "
         & (if Startup_Report.Host_AT_SPI_Address_Present
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""host_session_bus_address_present"": "
         & (if Startup_Report.Host_Session_Bus_Address_Present
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_discovery_attempted"": "
         & (if Startup_Report.Discovery_Attempted then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_discovery_raw_connect_attempted"": "
         & (if Startup_Report.Discovery.Raw_Connect_Attempted
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_discovery_raw_connect_status"": "
         & Q (Status_Name (Startup_Report.Discovery.Raw_Connect_Status))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_discovery_get_address_reply_status"": "
         & Q
             (Status_Name
                (Startup_Report.Discovery.Get_Address_Reply_Status))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_discovery_get_address_reply_error_name"": "
         & Q
             (To_String
                (Startup_Report.Discovery.Get_Address_Reply_Error_Name))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_discovery_get_address_completed"": "
         & (if Startup_Report.Discovery.Get_Address_Completed
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""node_count"": "
         & Natural'Image (A11y_Fixture_Report.Node_Count)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""command_result_count"": "
         & Natural'Image (Command_Result_Count)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""application_node"": "
         & Q (A11y.Node_Ids.Image (A11y_Test_Fixtures.Application_Id))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""application_exportable"": "
         & (if Session_View.Application.Exportable then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""application_path"": "
         & Q (To_String (Session_View.Application.Path))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""application_root_query"": "
         & (if Root_Query_OK then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""application_root_query_status"": "
         & Q (Status_Name (Root_Query_Status))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""application_root_role"": "
         & Natural'Image (Root_Role)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""application_root_child_count_query"": "
         & (if Root_Child_Count_OK then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""application_root_child_count_status"": "
         & Q (Status_Name (Root_Child_Count_Status))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""application_root_child_count"": "
         & Natural'Image (Root_Child_Count)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""application_root_first_child_query"": "
         & (if Root_First_Child_OK then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""application_root_first_child_status"": "
         & Q (Status_Name (Root_First_Child_Status))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""application_root_first_child"": "
         & Q (A11y.Node_Ids.Image (Root_First_Child))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""started"": "
         & (if Started then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registered"": "
         & (if Session_View.Registered then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_prepared"": "
         & (if Startup_Report.Prepared then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_backend_synchronized"": "
         & (if Startup_Report.Backend_Synchronized then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_backend_sync_status"": "
         & Q (Status_Name (Startup_Report.Backend_Synchronization.Status))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_backend_sync_before_state"": "
         & Q
           (A11y.Backends.Native_Backends.Name
              (Startup_Report.Backend_Synchronization.Backend_Before.State))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_backend_sync_after_state"": "
         & Q
           (A11y.Backends.Native_Backends.Name
              (Startup_Report.Backend_Synchronization.Backend_After.State))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_backend_sync_failure_record_attempted"": "
         & (if Startup_Report.Backend_Synchronization
             .Failure_Record_Attempted
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_backend_sync_transport_admission_attempted"": "
         & (if Startup_Report.Backend_Synchronization
             .Transport_Admission_Attempted
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_backend_sync_start_attempted"": "
         & (if Startup_Report.Backend_Synchronization
             .Backend_Start_Attempted
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_application_root_ensured"": "
         & (if Startup_Report.Application_Root_Ensured then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_address_resolved"": "
         & (if Startup_Report.Registration.Address_Resolved then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_address_transport"": "
         & Q
             (A11y.Linux.ATSPi_Bus.Transport_Name
                (Startup_Report.Registration.Address_Transport))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_address_field_count"": "
         & Natural'Image (Startup_Report.Registration.Address_Field_Count)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_address_uses_path"": "
         & (if Startup_Report.Registration.Address_Uses_Path
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_address_uses_abstract"": "
         & (if Startup_Report.Registration.Address_Uses_Abstract
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_raw_connect_attempted"": "
         & (if Startup_Report.Registration.Raw_Connect_Attempted
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_raw_connect_status"": "
         & Q (Status_Name (Startup_Report.Registration.Raw_Connect_Status))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_raw_connected"": "
         & (if Startup_Report.Registration.Raw_Connected then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_auth_sent"": "
         & (if Startup_Report.Registration.Auth_Sent then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_auth_response_status"": "
         & Q (Status_Name (Startup_Report.Registration.Auth_Response_Status))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_auth_accepted"": "
         & (if Startup_Report.Registration.Auth_Accepted then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_begin_sent"": "
         & (if Startup_Report.Registration.Begin_Sent then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_transport_admitted"": "
         & (if Startup_Report.Registration.Transport_Admitted then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_hello_queued"": "
         & (if Startup_Report.Registration.Hello_Queued then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_hello_sent"": "
         & (if Startup_Report.Registration.Hello_Sent then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_hello_reply_received"": "
         & (if Startup_Report.Registration.Hello_Reply_Received then "true"
            else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_hello_reply_serial"": "
         & Natural'Image (Startup_Report.Registration.Hello_Reply_Serial)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_hello_reply_status"": "
         & Q (Status_Name (Startup_Report.Registration.Hello_Reply_Status))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_hello_completed"": "
         & (if Startup_Report.Registration.Hello_Completed then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_unique_name_received"": "
         & (if Startup_Report.Registration.Unique_Name_Received
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_unique_name_length"": "
         & Natural'Image (Startup_Report.Registration.Unique_Name_Length)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_unique_name_has_bus_prefix"": "
         & (if Startup_Report.Registration.Unique_Name_Has_Bus_Prefix
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_application_object_path_available"": "
         & (if Startup_Report.Registration.Application_Object_Path_Available
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_application_object_path_length"": "
         & Natural'Image
             (Startup_Report.Registration.Application_Object_Path_Length)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_application_object_path_has_session_prefix"": "
         & (if Startup_Report.Registration
              .Application_Object_Path_Has_Session_Prefix
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_application_object_path_has_node_suffix"": "
         & (if Startup_Report.Registration
              .Application_Object_Path_Has_Node_Suffix
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_application_queued"": "
         & (if Startup_Report.Registration.Registration_Queued then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_application_sent"": "
         & (if Startup_Report.Registration.Registration_Sent then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_application_reply_received"": "
         & (if Startup_Report.Registration.Registration_Reply_Received
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_application_reply_serial"": "
         & Natural'Image
             (Startup_Report.Registration.Registration_Reply_Serial)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_application_reply_was_error_return"": "
         & (if Startup_Report.Registration.Registration_Reply_Was_Error_Return
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_application_reply_status"": "
         & Q
             (Status_Name
                (Startup_Report.Registration.Registration_Reply_Status))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_application_completed"": "
         & (if Startup_Report.Registration.Registration_Completed then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_transport_registration_observed"": "
         & (if Startup_Report.Registration.Transport_Registration_Observed
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registration_stage_status"": "
         & Q (Status_Name (Startup_Report.Registration.Status))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""transport_state"": "
         & Q (Transport_Name (Session_View.Transport.State))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_state"": "
         & Q (State_Name (Session_View.Startup_State))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""next_operation"": "
         & Q (Operation_Name (Session_View.Interest.Next_Operation))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""pending_outgoing"": "
         & Natural'Image (Session_View.Interest.Pending_Outgoing)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""in_flight_outgoing"": "
         & Natural'Image (Session_View.Interest.In_Flight_Outgoing)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""status"": "
         & Q (Status_Name (Final_Status))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""stop_status"": "
         & Q (Status_Name (Stop_Result.Status))
         & ASCII.LF);
      Append (Output, "}" & ASCII.LF);
      return To_String (Output);
   exception
      when others =>
         return
           "{"
           & ASCII.LF
           & "  ""schema"": "
           & Q ("org.a11y.fixture_atspi_startup.v1")
           & ","
           & ASCII.LF
           & "  ""fixture_schema"": "
           & Q (Schema)
           & ","
           & ASCII.LF
           & "  ""ready"": false,"
           & ASCII.LF
           & "  ""platform"": ""Linux"","
           & ASCII.LF
           & "  ""native_api"": ""AT-SPI2"","
           & ASCII.LF
           & "  ""address_supplied"": true,"
           & ASCII.LF
           & "  ""host_environment_used"": false,"
           & ASCII.LF
           & "  ""startup_source"": "
           & Q
             (if From_Environment
              then "environment_value"
              else "direct_address")
           & ","
           & ASCII.LF
           & "  ""started"": false,"
           & ASCII.LF
           & "  ""registered"": false,"
           & ASCII.LF
           & "  ""status"": ""INTERNAL_ERROR"","
           & ASCII.LF
           & "  ""stop_status"": ""INTERNAL_ERROR"""
           & ASCII.LF
           & "}"
           & ASCII.LF;
   end ATSPi_Startup_JSON_With_Mode;

   function ATSPi_Startup_JSON
     (Address : String;
      User_Id : Natural)
      return String is
     (ATSPi_Startup_JSON_With_Mode
        (Address, User_Id, From_Environment => False));

   function ATSPi_Environment_Startup_JSON
     (Value   : String;
      User_Id : Natural)
      return String is
     (ATSPi_Startup_JSON_With_Mode
        (Value, User_Id, From_Environment => True));

   function ATSPi_Host_Environment_Startup_JSON
     (User_Id : Natural)
      return String is
     (ATSPi_Startup_JSON_With_Mode
        ("", User_Id, From_Environment => False,
         From_Host_Environment => True));

   function ATSPi_Serve_JSON_With_Mode
     (Address               : String;
      User_Id               : Natural;
      Max_Iterations        : Natural;
      Read_Timeout_MS       : Natural;
      From_Host_Environment : Boolean)
      return String;

   function ATSPi_Serve_JSON
     (Address        : String;
      User_Id        : Natural;
      Max_Iterations : Natural)
      return String
   is
     (ATSPi_Serve_JSON
        (Address, User_Id, Max_Iterations, Read_Timeout_MS => 0));

   function ATSPi_Serve_JSON
     (Address         : String;
      User_Id         : Natural;
      Max_Iterations  : Natural;
      Read_Timeout_MS : Natural)
      return String is
     (ATSPi_Serve_JSON_With_Mode
        (Address, User_Id, Max_Iterations, Read_Timeout_MS,
         From_Host_Environment => False));

   function ATSPi_Host_Environment_Serve_JSON
     (User_Id        : Natural;
      Max_Iterations : Natural)
      return String
   is
     (ATSPi_Host_Environment_Serve_JSON
        (User_Id, Max_Iterations, Read_Timeout_MS => 0));

   function ATSPi_Host_Environment_Serve_JSON
     (User_Id         : Natural;
      Max_Iterations  : Natural;
      Read_Timeout_MS : Natural)
      return String is
     (ATSPi_Serve_JSON_With_Mode
        ("", User_Id, Max_Iterations, Read_Timeout_MS,
         From_Host_Environment => True));

   function ATSPi_Serve_JSON_With_Mode
     (Address               : String;
      User_Id               : Natural;
      Max_Iterations        : Natural;
      Read_Timeout_MS       : Natural;
      From_Host_Environment : Boolean)
      return String
   is
      type Session_Access is access
        A11y.Linux.ATSPi_Backend_Sessions.Backend_Session;
      type Snapshot_Bundle_Access is access
        A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Session_Ref : constant Session_Access :=
        new A11y.Linux.ATSPi_Backend_Sessions.Backend_Session;
      Session : A11y.Linux.ATSPi_Backend_Sessions.Backend_Session
      renames Session_Ref.all;
      Snapshots_Ref : constant Snapshot_Bundle_Access :=
        new A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle
      renames Snapshots_Ref.all;
      Result : A11y.Results.Result;
      Stop_Result : A11y.Results.Result;
      Pump_Result : A11y.Results.Result :=
        (Status => A11y.Results.Backend_Unavailable);
      Session_View :
        A11y.Linux.ATSPi_Backend_Sessions.Session_Report;
      Startup_Report :
        A11y.Linux.ATSPi_Backend_Sessions.Session_Startup_Report;
      Report : A11y.Linux.ATSPi_Startup.Pump_Bounded_Report;
      Loop_Report :
        A11y.Linux.ATSPi_Backend_Sessions.Event_Loop_Bounded_Report;
      Scheduler : A11y.Linux.ATSPi_Scheduler.Scheduler;
      Scheduler_Config : constant A11y.Linux.ATSPi_Scheduler.Scheduler_Config :=
        (Max_Iterations_Per_Run => 1,
         Read_Timeout_MS        => Integer (Read_Timeout_MS));
      Scheduler_Cycle_Report :
        A11y.Linux.ATSPi_Scheduler.Transport_Cycle_Run_Report;
      Scheduler_Cycle_Result : A11y.Results.Result :=
        (Status => A11y.Results.Backend_Unavailable);
      Scheduler_Configured : Boolean := False;
      Event_Loop_Steps_Attempted : Natural := 0;
      Event_Loop_Steps_Completed : Natural := 0;
      Event_Loop_Flushed         : Natural := 0;
      Last_Event_Loop_Operation :
        A11y.Linux.ATSPi_Startup.Event_Loop_Operation :=
          A11y.Linux.ATSPi_Startup.Wait_For_Transport;
      Last_Event_Loop_Stop_Reason :
        A11y.Linux.ATSPi_Startup.Pump_Bounded_Stop_Reason :=
          A11y.Linux.ATSPi_Startup.Not_Stopped;
      Step_Result : A11y.Results.Result :=
        (Status => A11y.Results.Backend_Unavailable);
      Started : Boolean := False;
      Root_Query_OK : Boolean := False;
      Root_Query_Status : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
      Root_Role : Natural := 0;
      Root_Child_Count_OK : Boolean := False;
      Root_Child_Count_Status : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
      Root_Child_Count : Natural := 0;
      Root_First_Child_OK : Boolean := False;
      Root_First_Child_Status : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
      Root_First_Child : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Final_Status : A11y.Results.Status_Code := A11y.Results.Success;
      Output : Unbounded_String;
   begin
      Configure_ATSPi_Root_Snapshot (Snapshots);
      if From_Host_Environment then
         A11y.Linux.ATSPi_Backend_Sessions
           .Start_From_Host_Environment_With_Report
           (Session,
            A11y.Linux.DBus_Auth.External_User_Id (User_Id),
            A11y_Test_Fixtures.Application_Id,
            Startup_Report,
            Result);
      else
         A11y.Linux.ATSPi_Backend_Sessions.Start_From_Address_With_Report
           (Session,
            Address,
            A11y.Linux.DBus_Auth.External_User_Id (User_Id),
            A11y_Test_Fixtures.Application_Id,
            Startup_Report,
            Result);
      end if;
      A11y.Linux.ATSPi_Backend_Sessions.Capture_Report
        (Session, Session_View);
      Started := Session_View.Transport.State =
        A11y.Backends.Native_Backends.Transport_Running;

      if A11y.Results.Succeeded (Result) and then Session_View.Registered then
         declare
            Root_Reply : constant
              A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply :=
                A11y.Linux.ATSPi_Backend_Sessions
                  .Dispatch_Application_Root_Method
                    (Session,
                     A11y.Linux.ATSPi_Objects.Accessible,
                     "GetRole",
                     Snapshots);
         begin
            Root_Query_Status := Root_Reply.Status;
            if Root_Reply.Kind =
                A11y.Linux.ATSPi_DBus_Boundary.Method_Reply
              and then Root_Reply.Routed_Kind =
                A11y.Linux.ATSPi_Method_Router.Accessible_Role
              and then Root_Reply.Status = A11y.Results.Success
            then
               Root_Query_OK := True;
               Root_Role := Root_Reply.UInt32;
            end if;
         end;

         declare
            Child_Count_Reply : constant
              A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply :=
                A11y.Linux.ATSPi_Backend_Sessions
                  .Dispatch_Application_Root_Method
                    (Session,
                     A11y.Linux.ATSPi_Objects.Accessible,
                     "GetChildCount",
                     Snapshots);
         begin
            Root_Child_Count_Status := Child_Count_Reply.Status;
            if Child_Count_Reply.Kind =
                A11y.Linux.ATSPi_DBus_Boundary.Method_Reply
              and then Child_Count_Reply.Routed_Kind =
                A11y.Linux.ATSPi_Method_Router.Accessible_UInt32
              and then Child_Count_Reply.Status = A11y.Results.Success
            then
               Root_Child_Count_OK := True;
               Root_Child_Count := Child_Count_Reply.UInt32;
            end if;
         end;

         declare
            Child_Reply : constant
              A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply :=
                A11y.Linux.ATSPi_Backend_Sessions
                  .Dispatch_Application_Root_Method
                    (Session,
                     A11y.Linux.ATSPi_Objects.Accessible,
                     "GetChildAtIndex",
                     0,
                     Snapshots);
         begin
            Root_First_Child_Status := Child_Reply.Status;
            if Child_Reply.Kind =
                A11y.Linux.ATSPi_DBus_Boundary.Method_Reply
              and then Child_Reply.Routed_Kind =
                A11y.Linux.ATSPi_Method_Router.Accessible_Node
              and then Child_Reply.Status = A11y.Results.Success
            then
               Root_First_Child_OK := True;
               Root_First_Child := Child_Reply.Node;
            end if;
         end;

         A11y.Linux.ATSPi_Backend_Sessions.Drive_Bounded_Event_Loop
           (Session,
            Snapshots,
            Max_Iterations,
            Integer (Read_Timeout_MS),
            Loop_Report,
            Step_Result);
         Report := Loop_Report.Pump;
         Event_Loop_Steps_Attempted := Loop_Report.Steps_Attempted;
         Event_Loop_Steps_Completed := Loop_Report.Steps_Completed;
         Event_Loop_Flushed := Loop_Report.Flushed;
         Last_Event_Loop_Operation := Loop_Report.Last_Operation;
         Last_Event_Loop_Stop_Reason :=
           Loop_Report.Last_Step_Stop_Reason;
         Pump_Result := Step_Result;
         A11y.Linux.ATSPi_Backend_Sessions.Capture_Report
           (Session, Session_View);

         A11y.Linux.ATSPi_Scheduler.Configure
           (Scheduler, Scheduler_Config, Scheduler_Cycle_Result);
         Scheduler_Configured := A11y.Results.Succeeded
           (Scheduler_Cycle_Result);
         if Scheduler_Configured then
            A11y.Linux.ATSPi_Scheduler.Run_One_Transport_Cycle
              (Scheduler,
               Session,
               Snapshots,
               Scheduler_Cycle_Report,
               Scheduler_Cycle_Result);
         end if;
      else
         Report :=
           (Iterations_Attempted => Max_Iterations,
            Iterations_Completed => 0,
            Reads_Attempted      => 0,
            Packets_Received     => 0,
            Packets_Dispatched   => 0,
            Replies_Written      => 0,
            Registered_Method_Calls  => 0,
            Registered_Replies       => 0,
            Registered_Replies_In_Flight => 0,
            Registered_Drained_Calls => 0,
            Registered_Boundary_Resolved_Calls  => 0,
            Registered_Boundary_Admitted_Calls  => 0,
            Registered_Boundary_Completed_Calls => 0,
            Last_Registered_Incoming_Kind =>
              A11y.Linux.DBus_Messages.Error_Return,
            Last_Registered_Incoming_Serial => 0,
            Last_Registered_Incoming_Reply_Serial => 0,
            Last_Registered_Reply_Kind =>
              A11y.Linux.DBus_Messages.Error_Return,
            Last_Registered_Reply_Serial => 0,
            Last_Registered_Reply_Reply_Serial => 0,
            Last_Registered_Reply_Estimated_Bytes => 0,
            Last_Registered_Reply_In_Flight => False,
            Last_Registered_Boundary_Status =>
              A11y.Results.Node_Unavailable,
            Last_Registered_Begin_Outstanding_Before => 0,
            Last_Registered_Begin_Outstanding_After  => 0,
            Last_Registered_End_Outstanding_Before   => 0,
            Last_Registered_End_Outstanding_After    => 0,
            Pending_Outgoing     => 0,
            In_Flight_Outgoing   => 0,
            Stop_Reason          =>
              A11y.Linux.ATSPi_Startup.Readiness_Failed,
            Status               =>
              (if A11y.Results.Failed (Result)
               then Result.Status
               else A11y.Results.Backend_Unavailable));
         Pump_Result := (Status => Report.Status);
         Scheduler_Cycle_Report.Status := Report.Status;
         Scheduler_Cycle_Report.Cycle.Status := Report.Status;
      end if;

      Final_Status :=
        (if A11y.Results.Failed (Result)
         then Result.Status
         elsif A11y.Results.Failed (Pump_Result)
         then Pump_Result.Status
         else Session_View.Transport.Last_Status);

      A11y.Linux.ATSPi_Backend_Sessions.Stop (Session, Stop_Result);
      if A11y.Results.Succeeded ((Status => Final_Status))
        and then A11y.Results.Failed (Stop_Result)
      then
         Final_Status := Stop_Result.Status;
      end if;

      Append (Output, "{" & ASCII.LF);
      Append
        (Output,
         "  ""schema"": "
         & Q ("org.a11y.fixture_atspi_serve.v1")
         & ","
         & ASCII.LF);
      Append (Output, "  ""fixture_schema"": " & Q (Schema) & "," & ASCII.LF);
      Append (Output, "  ""ready"": true," & ASCII.LF);
      Append (Output, "  ""platform"": ""Linux""," & ASCII.LF);
      Append (Output, "  ""native_api"": ""AT-SPI2""," & ASCII.LF);
      Append
        (Output,
         "  ""address_supplied"": "
         & (if From_Host_Environment then "false" else "true")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""host_environment_used"": "
         & (if From_Host_Environment then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_source"": "
         & Q
           (A11y.Linux.ATSPi_Backend_Sessions.Startup_Source_Name
              (Startup_Report.Source))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""host_at_spi_bus_address_present"": "
         & (if Startup_Report.Host_AT_SPI_Address_Present
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""host_session_bus_address_present"": "
         & (if Startup_Report.Host_Session_Bus_Address_Present
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_discovery_attempted"": "
         & (if Startup_Report.Discovery_Attempted then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_discovery_raw_connect_attempted"": "
         & (if Startup_Report.Discovery.Raw_Connect_Attempted
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_discovery_raw_connect_status"": "
         & Q (Status_Name (Startup_Report.Discovery.Raw_Connect_Status))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_discovery_get_address_reply_status"": "
         & Q
           (Status_Name
              (Startup_Report.Discovery.Get_Address_Reply_Status))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_discovery_get_address_reply_error_name"": "
         & Q (To_String
                (Startup_Report.Discovery.Get_Address_Reply_Error_Name))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_discovery_get_address_completed"": "
         & (if Startup_Report.Discovery.Get_Address_Completed
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""max_iterations"": "
         & Natural'Image (Max_Iterations)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""read_timeout_ms"": "
         & Natural'Image (Read_Timeout_MS)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""node_count"": "
         & Natural'Image (A11y_Fixture_Report.Node_Count)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""application_node"": "
         & Q (A11y.Node_Ids.Image (A11y_Test_Fixtures.Application_Id))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""application_exportable"": "
         & (if Session_View.Application.Exportable then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""application_path"": "
         & Q (To_String (Session_View.Application.Path))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""application_root_query"": "
         & (if Root_Query_OK then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""application_root_query_status"": "
         & Q (Status_Name (Root_Query_Status))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""application_root_role"": "
         & Natural'Image (Root_Role)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""application_root_child_count_query"": "
         & (if Root_Child_Count_OK then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""application_root_child_count_status"": "
         & Q (Status_Name (Root_Child_Count_Status))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""application_root_child_count"": "
         & Natural'Image (Root_Child_Count)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""application_root_first_child_query"": "
         & (if Root_First_Child_OK then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""application_root_first_child_status"": "
         & Q (Status_Name (Root_First_Child_Status))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""application_root_first_child"": "
         & Q (A11y.Node_Ids.Image (Root_First_Child))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""started"": "
         & (if Started then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registered"": "
         & (if Session_View.Registered then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""transport_state"": "
         & Q (Transport_Name (Session_View.Transport.State))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""startup_state"": "
         & Q (State_Name (Session_View.Startup_State))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""next_operation"": "
         & Q (Operation_Name (Session_View.Interest.Next_Operation))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""event_loop_can_read"": "
         & (if Session_View.Interest.Can_Read then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""event_loop_can_write"": "
         & (if Session_View.Interest.Can_Write then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""event_loop_can_dispatch"": "
         & (if Session_View.Interest.Can_Dispatch then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""event_loop_has_outgoing_work"": "
         & (if Session_View.Interest.Has_Outgoing_Work
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""event_loop_after_next_operation"": "
         & Q (Operation_Name (Loop_Report.Last_Interest_After.Next_Operation))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""event_loop_after_can_read"": "
         & (if Loop_Report.Last_Interest_After.Can_Read
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""event_loop_after_can_write"": "
         & (if Loop_Report.Last_Interest_After.Can_Write
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""event_loop_after_can_dispatch"": "
         & (if Loop_Report.Last_Interest_After.Can_Dispatch
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""event_loop_after_has_outgoing_work"": "
         & (if Loop_Report.Last_Interest_After.Has_Outgoing_Work
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""event_loop_steps_attempted"": "
         & Natural'Image (Event_Loop_Steps_Attempted)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""event_loop_steps_completed"": "
         & Natural'Image (Event_Loop_Steps_Completed)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""event_loop_wait_attempts"": "
         & Natural'Image (Loop_Report.Wait_Attempts)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""event_loop_wait_timeouts"": "
         & Natural'Image (Loop_Report.Wait_Timeouts)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""event_loop_wait_readable"": "
         & Natural'Image (Loop_Report.Wait_Readable)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""event_loop_write_attempts"": "
         & Natural'Image (Loop_Report.Write_Attempts)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""event_loop_write_ready"": "
         & Natural'Image (Loop_Report.Write_Ready)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""event_loop_write_timeouts"": "
         & Natural'Image (Loop_Report.Write_Timeouts)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""event_loop_flushed"": "
         & Natural'Image (Event_Loop_Flushed)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""last_event_loop_operation"": "
         & Q (Operation_Name (Last_Event_Loop_Operation))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""last_event_loop_stop_reason"": "
         & Q (Stop_Reason_Name (Last_Event_Loop_Stop_Reason))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""event_loop_step_status"": "
         & Q (Status_Name (Loop_Report.Last_Step_Status))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_configured"": "
         & (if Scheduler_Configured then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_attempted"": "
         & (if Scheduler_Cycle_Report.Run_Attempted
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_status"": "
         & Q (Status_Name (Scheduler_Cycle_Result.Status))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_interest_before"": "
         & Q
             (Operation_Name
                (Scheduler_Cycle_Report.Interest_Before.Next_Operation))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_interest_after"": "
         & Q
             (Operation_Name
                (Scheduler_Cycle_Report.Interest_After.Next_Operation))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_wait_attempted"": "
         & (if Scheduler_Cycle_Report.Wait_Attempted
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_wait_status"": "
         & Q (Status_Name (Scheduler_Cycle_Report.Wait_Status))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_wait_timed_out"": "
         & (if Scheduler_Cycle_Report.Wait_Timed_Out
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_wait_readable"": "
         & (if Scheduler_Cycle_Report.Wait_Readable
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_write_wait_attempted"": "
         & (if Scheduler_Cycle_Report.Write_Wait_Attempted
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_write_wait_status"": "
         & Q (Status_Name (Scheduler_Cycle_Report.Write_Wait_Status))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_write_wait_timed_out"": "
         & (if Scheduler_Cycle_Report.Write_Wait_Timed_Out
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_write_wait_ready"": "
         & (if Scheduler_Cycle_Report.Write_Wait_Ready
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_flushed"": "
         & Natural'Image (Scheduler_Cycle_Report.Flushed)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_ready_checked"": "
         & (if Scheduler_Cycle_Report.Cycle.Ready_Checked
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_read_attempted"": "
         & (if Scheduler_Cycle_Report.Cycle.Read_Attempted
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_incoming_kind"": "
         & Q
             (A11y.Linux.DBus_Messages.Message_Kind'Image
                (Scheduler_Cycle_Report.Cycle.Incoming_Packet_Kind))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_incoming_serial"": "
         & Natural'Image (Scheduler_Cycle_Report.Cycle.Incoming_Serial)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_incoming_reply_serial"": "
         & Natural'Image (Scheduler_Cycle_Report.Cycle.Incoming_Reply_Serial)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_incoming_estimated_bytes"": "
         & Natural'Image
             (Scheduler_Cycle_Report.Cycle.Incoming_Estimated_Bytes)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_serve_attempted"": "
         & (if Scheduler_Cycle_Report.Cycle.Serve_Attempted
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_write_attempted"": "
         & (if Scheduler_Cycle_Report.Cycle.Write_Attempted
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_reply_kind"": "
         & Q
             (A11y.Linux.DBus_Messages.Message_Kind'Image
                (Scheduler_Cycle_Report.Cycle.Reply_Packet_Kind))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_reply_serial"": "
         & Natural'Image (Scheduler_Cycle_Report.Cycle.Reply_Serial)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_reply_reply_serial"": "
         & Natural'Image (Scheduler_Cycle_Report.Cycle.Reply_Reply_Serial)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_reply_estimated_bytes"": "
         & Natural'Image
             (Scheduler_Cycle_Report.Cycle.Reply_Estimated_Bytes)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_registered_method_call"": "
         & (if Scheduler_Cycle_Report.Cycle.Registered.Incoming_Method_Call
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""scheduler_transport_cycle_registered_reply_serialized"": "
         & (if Scheduler_Cycle_Report.Cycle.Registered.Reply_Serialized
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""iterations_attempted"": "
         & Natural'Image (Report.Iterations_Attempted)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""iterations_completed"": "
         & Natural'Image (Report.Iterations_Completed)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""packets_received"": "
         & Natural'Image (Report.Packets_Received)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""packets_dispatched"": "
         & Natural'Image (Report.Packets_Dispatched)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""replies_written"": "
         & Natural'Image (Report.Replies_Written)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registered_method_calls"": "
         & Natural'Image (Report.Registered_Method_Calls)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registered_replies"": "
         & Natural'Image (Report.Registered_Replies)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registered_replies_in_flight"": "
         & Natural'Image (Report.Registered_Replies_In_Flight)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registered_drained_calls"": "
         & Natural'Image (Report.Registered_Drained_Calls)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registered_boundary_resolved_calls"": "
         & Natural'Image (Report.Registered_Boundary_Resolved_Calls)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registered_boundary_admitted_calls"": "
         & Natural'Image (Report.Registered_Boundary_Admitted_Calls)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""registered_boundary_completed_calls"": "
         & Natural'Image (Report.Registered_Boundary_Completed_Calls)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""last_registered_incoming_kind"": "
         & Q
             (A11y.Linux.DBus_Messages.Message_Kind'Image
                (Report.Last_Registered_Incoming_Kind))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""last_registered_incoming_serial"": "
         & Natural'Image (Report.Last_Registered_Incoming_Serial)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""last_registered_incoming_reply_serial"": "
         & Natural'Image (Report.Last_Registered_Incoming_Reply_Serial)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""last_registered_reply_kind"": "
         & Q
             (A11y.Linux.DBus_Messages.Message_Kind'Image
                (Report.Last_Registered_Reply_Kind))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""last_registered_reply_serial"": "
         & Natural'Image (Report.Last_Registered_Reply_Serial)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""last_registered_reply_reply_serial"": "
         & Natural'Image (Report.Last_Registered_Reply_Reply_Serial)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""last_registered_reply_estimated_bytes"": "
         & Natural'Image (Report.Last_Registered_Reply_Estimated_Bytes)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""last_registered_reply_in_flight"": "
         & (if Report.Last_Registered_Reply_In_Flight
            then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""last_registered_boundary_status"": "
         & Q (Status_Name (Report.Last_Registered_Boundary_Status))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""last_registered_begin_outstanding_before"": "
         & Natural'Image
             (Report.Last_Registered_Begin_Outstanding_Before)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""last_registered_begin_outstanding_after"": "
         & Natural'Image
             (Report.Last_Registered_Begin_Outstanding_After)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""last_registered_end_outstanding_before"": "
         & Natural'Image
             (Report.Last_Registered_End_Outstanding_Before)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""last_registered_end_outstanding_after"": "
         & Natural'Image
             (Report.Last_Registered_End_Outstanding_After)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""pending_outgoing"": "
         & Natural'Image (Report.Pending_Outgoing)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""in_flight_outgoing"": "
         & Natural'Image (Report.In_Flight_Outgoing)
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""pump_stop_reason"": "
         & Q (Stop_Reason_Name (Report.Stop_Reason))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""pump_status"": "
         & Q (Status_Name (Pump_Result.Status))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""status"": "
         & Q (Status_Name (Final_Status))
         & ","
         & ASCII.LF);
      Append
        (Output,
         "  ""stop_status"": "
         & Q (Status_Name (Stop_Result.Status))
         & ASCII.LF);
      Append (Output, "}" & ASCII.LF);
      return To_String (Output);
   exception
      when others =>
         return
           "{"
           & ASCII.LF
           & "  ""schema"": "
           & Q ("org.a11y.fixture_atspi_serve.v1")
           & ","
           & ASCII.LF
           & "  ""fixture_schema"": "
           & Q (Schema)
           & ","
           & ASCII.LF
           & "  ""ready"": false,"
           & ASCII.LF
           & "  ""platform"": ""Linux"","
           & ASCII.LF
           & "  ""native_api"": ""AT-SPI2"","
           & ASCII.LF
           & "  ""address_supplied"": true,"
           & ASCII.LF
           & "  ""startup_discovery_attempted"": false,"
           & ASCII.LF
           & "  ""startup_discovery_raw_connect_attempted"": false,"
           & ASCII.LF
           & "  ""startup_discovery_raw_connect_status"": "
           & """INTERNAL_ERROR"","
           & ASCII.LF
           & "  ""startup_discovery_get_address_reply_status"": "
           & """INTERNAL_ERROR"","
           & ASCII.LF
           & "  ""startup_discovery_get_address_reply_error_name"": """","
           & ASCII.LF
           & "  ""startup_discovery_get_address_completed"": false,"
           & ASCII.LF
           & "  ""started"": false,"
           & ASCII.LF
           & "  ""registered"": false,"
           & ASCII.LF
           & "  ""event_loop_can_read"": false,"
           & ASCII.LF
           & "  ""event_loop_can_write"": false,"
           & ASCII.LF
           & "  ""event_loop_can_dispatch"": false,"
           & ASCII.LF
           & "  ""event_loop_has_outgoing_work"": false,"
           & ASCII.LF
           & "  ""event_loop_after_next_operation"": ""WAIT_FOR_TRANSPORT"","
           & ASCII.LF
           & "  ""event_loop_after_can_read"": false,"
           & ASCII.LF
           & "  ""event_loop_after_can_write"": false,"
           & ASCII.LF
           & "  ""event_loop_after_can_dispatch"": false,"
           & ASCII.LF
           & "  ""event_loop_after_has_outgoing_work"": false,"
           & ASCII.LF
           & "  ""event_loop_write_attempts"": 0,"
           & ASCII.LF
           & "  ""event_loop_write_ready"": 0,"
           & ASCII.LF
           & "  ""event_loop_write_timeouts"": 0,"
           & ASCII.LF
           & "  ""scheduler_transport_cycle_configured"": false,"
           & ASCII.LF
           & "  ""scheduler_transport_cycle_attempted"": false,"
           & ASCII.LF
           & "  ""scheduler_transport_cycle_status"": ""INTERNAL_ERROR"","
           & ASCII.LF
           & "  ""scheduler_transport_cycle_interest_before"": ""WAIT_FOR_TRANSPORT"","
           & ASCII.LF
           & "  ""scheduler_transport_cycle_interest_after"": ""WAIT_FOR_TRANSPORT"","
           & ASCII.LF
           & "  ""scheduler_transport_cycle_wait_attempted"": false,"
           & ASCII.LF
           & "  ""scheduler_transport_cycle_wait_status"": ""INTERNAL_ERROR"","
           & ASCII.LF
           & "  ""scheduler_transport_cycle_wait_timed_out"": false,"
           & ASCII.LF
           & "  ""scheduler_transport_cycle_wait_readable"": false,"
           & ASCII.LF
           & "  ""scheduler_transport_cycle_write_wait_attempted"": false,"
           & ASCII.LF
           & "  ""scheduler_transport_cycle_write_wait_status"": ""INTERNAL_ERROR"","
           & ASCII.LF
           & "  ""scheduler_transport_cycle_write_wait_timed_out"": false,"
           & ASCII.LF
           & "  ""scheduler_transport_cycle_write_wait_ready"": false,"
           & ASCII.LF
           & "  ""scheduler_transport_cycle_flushed"": 0,"
           & ASCII.LF
           & "  ""scheduler_transport_cycle_ready_checked"": false,"
           & ASCII.LF
           & "  ""scheduler_transport_cycle_read_attempted"": false,"
           & ASCII.LF
           & "  ""scheduler_transport_cycle_incoming_kind"": ""ERROR_RETURN"","
           & ASCII.LF
           & "  ""scheduler_transport_cycle_incoming_serial"": 0,"
           & ASCII.LF
           & "  ""scheduler_transport_cycle_incoming_reply_serial"": 0,"
           & ASCII.LF
           & "  ""scheduler_transport_cycle_incoming_estimated_bytes"": 0,"
           & ASCII.LF
           & "  ""scheduler_transport_cycle_serve_attempted"": false,"
           & ASCII.LF
           & "  ""scheduler_transport_cycle_write_attempted"": false,"
           & ASCII.LF
           & "  ""scheduler_transport_cycle_reply_kind"": ""ERROR_RETURN"","
           & ASCII.LF
           & "  ""scheduler_transport_cycle_reply_serial"": 0,"
           & ASCII.LF
           & "  ""scheduler_transport_cycle_reply_reply_serial"": 0,"
           & ASCII.LF
           & "  ""scheduler_transport_cycle_reply_estimated_bytes"": 0,"
           & ASCII.LF
           & "  ""scheduler_transport_cycle_registered_method_call"": false,"
           & ASCII.LF
           & "  ""scheduler_transport_cycle_registered_reply_serialized"": false,"
           & ASCII.LF
           & "  ""registered_replies_in_flight"": 0,"
           & ASCII.LF
           & "  ""last_registered_incoming_kind"": ""ERROR_RETURN"","
           & ASCII.LF
           & "  ""last_registered_incoming_serial"": 0,"
           & ASCII.LF
           & "  ""last_registered_incoming_reply_serial"": 0,"
           & ASCII.LF
           & "  ""last_registered_reply_kind"": ""ERROR_RETURN"","
           & ASCII.LF
           & "  ""last_registered_reply_serial"": 0,"
           & ASCII.LF
           & "  ""last_registered_reply_reply_serial"": 0,"
           & ASCII.LF
           & "  ""last_registered_reply_estimated_bytes"": 0,"
           & ASCII.LF
           & "  ""last_registered_reply_in_flight"": false,"
           & ASCII.LF
           & "  ""last_event_loop_stop_reason"": ""ITERATION_FAILED"","
           & ASCII.LF
           & "  ""pump_status"": ""INTERNAL_ERROR"","
           & ASCII.LF
           & "  ""status"": ""INTERNAL_ERROR"","
           & ASCII.LF
           & "  ""stop_status"": ""INTERNAL_ERROR"""
           & ASCII.LF
           & "}"
           & ASCII.LF;
   end ATSPi_Serve_JSON_With_Mode;

   function JSON return String is
      Result : Unbounded_String;
      First : Boolean := True;
      Index : Natural := 0;
   begin
      Append (Result, "{" & ASCII.LF);
      Append (Result, "  ""schema"": " & Q (Schema) & "," & ASCII.LF);
      Append (Result, "  ""ready"": true," & ASCII.LF);
      Append
        (Result,
         "  ""node_count"": "
         & Natural'Image (A11y_Fixture_Report.Node_Count)
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""command_result_count"": "
         & Natural'Image (Command_Result_Count)
         & ","
         & ASCII.LF);
      Append (Result, "  ""results"": [" & ASCII.LF);

      for Command of A11y_Test_Fixtures.Script loop
         Index := Index + 1;
         if First then
            First := False;
         else
            Append (Result, "," & ASCII.LF);
         end if;

         Append
           (Result,
            "    {"
            & """index"": "
            & Natural'Image (Index)
            & ", ""command"": "
            & Q (Command_Name (Command.Kind))
            & ", ""target"": "
            & Q (A11y.Node_Ids.Image (Command.Target))
            & ", ""status"": "
            & Q ("accepted")
            & "}");
      end loop;

      Append (Result, ASCII.LF & "  ]" & ASCII.LF & "}" & ASCII.LF);
      return To_String (Result);
   end JSON;

end A11y_Fixture_Application;
