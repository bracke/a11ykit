with Ada.Command_Line;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with A11y_Fixture_Application;
with A11y.Results;
with Hostkit.Process;

procedure Fixture_Application is
   use Ada.Strings.Unbounded;

   ATSPI_Address_Prefix : constant String := "--atspi-address=";
   ATSPI_Environment_Address_Prefix : constant String :=
     "--atspi-env-address=";
   ATSPI_Host_Environment_Arg : constant String := "--atspi-host-env";
   ATSPI_Serve_Address_Prefix : constant String := "--atspi-serve-address=";
   ATSPI_Serve_Host_Environment_Arg : constant String :=
     "--atspi-serve-host-env";
   ATSPI_Serve_Iterations_Prefix : constant String :=
     "--atspi-serve-iterations=";
   ATSPI_Serve_Timeout_Prefix : constant String :=
     "--atspi-serve-timeout-ms=";
   ATSPI_UID_Prefix     : constant String := "--atspi-uid=";

   function Has_Prefix (Text, Prefix : String) return Boolean is
     (Text'Length >= Prefix'Length
      and then Text (Text'First .. Text'First + Prefix'Length - 1) =
        Prefix);

   function Parse_UID
     (Text   : String;
      Result : out A11y.Results.Result)
      return Natural
   is
   begin
      Result := A11y.Results.Ok;
      return Natural'Value (Text);
   exception
      when others =>
         Result := (Status => A11y.Results.Invalid_Argument);
         return 0;
   end Parse_UID;

   function Default_UID return Natural is
      Host_User_Id : Natural := 0;
   begin
      if Hostkit.Process.Current_User_Id (Host_User_Id) then
         return Host_User_Id;
      else
         return 0;
      end if;
   exception
      when others =>
         return 0;
   end Default_UID;

   ATSPI_Address : Unbounded_String := Null_Unbounded_String;
   ATSPI_Environment_Address : Unbounded_String := Null_Unbounded_String;
   ATSPI_Host_Environment : Boolean := False;
   ATSPI_Serve_Address : Unbounded_String := Null_Unbounded_String;
   ATSPI_Serve_Host_Environment : Boolean := False;
   Serve_Iterations : Natural := 1;
   Serve_Timeout_MS : Natural := 0;
   UID : Natural := Default_UID;
   Parse_Result : A11y.Results.Result := A11y.Results.Ok;
begin
   for Index in 1 .. Ada.Command_Line.Argument_Count loop
      declare
         Arg : constant String := Ada.Command_Line.Argument (Index);
      begin
         if Has_Prefix (Arg, ATSPI_Address_Prefix) then
            ATSPI_Address := To_Unbounded_String
              (Arg (Arg'First + ATSPI_Address_Prefix'Length .. Arg'Last));
         elsif Has_Prefix (Arg, ATSPI_Environment_Address_Prefix) then
            ATSPI_Environment_Address := To_Unbounded_String
              (Arg
                 (Arg'First + ATSPI_Environment_Address_Prefix'Length
                  .. Arg'Last));
         elsif Arg = ATSPI_Host_Environment_Arg then
            ATSPI_Host_Environment := True;
         elsif Has_Prefix (Arg, ATSPI_Serve_Address_Prefix) then
            ATSPI_Serve_Address := To_Unbounded_String
              (Arg
                 (Arg'First + ATSPI_Serve_Address_Prefix'Length
                  .. Arg'Last));
         elsif Arg = ATSPI_Serve_Host_Environment_Arg then
            ATSPI_Serve_Host_Environment := True;
         elsif Has_Prefix (Arg, ATSPI_Serve_Iterations_Prefix) then
            Serve_Iterations := Parse_UID
              (Arg
                 (Arg'First + ATSPI_Serve_Iterations_Prefix'Length
                  .. Arg'Last),
               Parse_Result);
         elsif Has_Prefix (Arg, ATSPI_Serve_Timeout_Prefix) then
            Serve_Timeout_MS := Parse_UID
              (Arg
                 (Arg'First + ATSPI_Serve_Timeout_Prefix'Length
                  .. Arg'Last),
               Parse_Result);
         elsif Has_Prefix (Arg, ATSPI_UID_Prefix) then
            UID := Parse_UID
              (Arg (Arg'First + ATSPI_UID_Prefix'Length .. Arg'Last),
               Parse_Result);
         end if;
      end;
   end loop;

   if A11y.Results.Failed (Parse_Result) then
      Ada.Text_IO.Put_Line
        ("{""schema"": ""org.a11y.fixture_atspi_startup.v1"", "
         & """ready"": false, ""status"": ""INVALID_ARGUMENT""}");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   elsif Length (ATSPI_Address) /= 0 then
      Ada.Text_IO.Put
        (A11y_Fixture_Application.ATSPi_Startup_JSON
           (To_String (ATSPI_Address), UID));
   elsif Length (ATSPI_Environment_Address) /= 0 then
      Ada.Text_IO.Put
        (A11y_Fixture_Application.ATSPi_Environment_Startup_JSON
           (To_String (ATSPI_Environment_Address), UID));
   elsif ATSPI_Host_Environment then
      Ada.Text_IO.Put
        (A11y_Fixture_Application.ATSPi_Host_Environment_Startup_JSON
           (UID));
   elsif Length (ATSPI_Serve_Address) /= 0 then
      Ada.Text_IO.Put
        (A11y_Fixture_Application.ATSPi_Serve_JSON
           (To_String (ATSPI_Serve_Address),
            UID,
            Serve_Iterations,
            Serve_Timeout_MS));
   elsif ATSPI_Serve_Host_Environment then
      Ada.Text_IO.Put
        (A11y_Fixture_Application.ATSPi_Host_Environment_Serve_JSON
           (UID,
            Serve_Iterations,
            Serve_Timeout_MS));
   elsif Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--json"
   then
      Ada.Text_IO.Put (A11y_Fixture_Application.JSON);
   elsif Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--ready"
   then
      Ada.Text_IO.Put_Line (A11y_Fixture_Application.Readiness_Line);
   elsif Ada.Command_Line.Argument_Count = 0 then
      Ada.Text_IO.Put (A11y_Fixture_Application.Results_Text);
   else
      Ada.Text_IO.Put_Line
        ("usage: fixture_application [--ready|--json|--atspi-address=ADDR "
         & "|--atspi-env-address=AT_SPI_BUS_ADDRESS "
         & "|--atspi-host-env "
         & "|--atspi-serve-address=ADDR "
         & "|--atspi-serve-host-env "
         & "[--atspi-serve-iterations=N] "
         & "[--atspi-serve-timeout-ms=N] [--atspi-uid=UID]]");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Fixture_Application;
