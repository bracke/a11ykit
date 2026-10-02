with Ada.Command_Line;
with Ada.Directories;
with Ada.Sequential_IO;
with Ada.Streams;
with Ada.Strings.Fixed;
with Ada.Text_IO;

with GNAT.Sockets;

procedure Windows_VM_Probe is
   VM_Dir : constant String := "vm/windows11";

   package Character_IO is new Ada.Sequential_IO (Character);

   function Exists (Path : String) return Boolean is
   begin
      return Ada.Directories.Exists (Path);
   exception
      when others =>
         return False;
   end Exists;

   function TCP_Connectable (Port : Natural) return Boolean is
      Address : GNAT.Sockets.Sock_Addr_Type;
      Channel : GNAT.Sockets.Socket_Type;
   begin
      GNAT.Sockets.Create_Socket (Channel);
      Address.Addr := GNAT.Sockets.Inet_Addr ("127.0.0.1");
      Address.Port := GNAT.Sockets.Port_Type (Port);
      GNAT.Sockets.Connect_Socket (Channel, Address);
      GNAT.Sockets.Close_Socket (Channel);
      return True;
   exception
      when others =>
         begin
            GNAT.Sockets.Close_Socket (Channel);
         exception
            when others =>
               null;
         end;
         return False;
   end TCP_Connectable;

   function SSH_Banner_Responsive (Port : Natural) return Boolean is
      use type Ada.Streams.Stream_Element_Offset;

      Address : GNAT.Sockets.Sock_Addr_Type;
      Channel : GNAT.Sockets.Socket_Type;
      Buffer  : Ada.Streams.Stream_Element_Array (1 .. 8);
      Last    : Ada.Streams.Stream_Element_Offset;
   begin
      GNAT.Sockets.Create_Socket (Channel);
      GNAT.Sockets.Set_Socket_Option
        (Channel,
         GNAT.Sockets.Socket_Level,
         (Name => GNAT.Sockets.Receive_Timeout, Timeout => 2.0));
      Address.Addr := GNAT.Sockets.Inet_Addr ("127.0.0.1");
      Address.Port := GNAT.Sockets.Port_Type (Port);
      GNAT.Sockets.Connect_Socket (Channel, Address);
      GNAT.Sockets.Receive_Socket (Channel, Buffer, Last);
      GNAT.Sockets.Close_Socket (Channel);

      return Last >= 4
        and then Character'Val (Buffer (1)) = 'S'
        and then Character'Val (Buffer (2)) = 'S'
        and then Character'Val (Buffer (3)) = 'H'
        and then Character'Val (Buffer (4)) = '-';
   exception
      when others =>
         begin
            GNAT.Sockets.Close_Socket (Channel);
         exception
            when others =>
               null;
         end;
         return False;
   end SSH_Banner_Responsive;

   function Listening_Port (Hex_Port : String) return Boolean is
      use Ada.Strings.Fixed;

      function In_File (Path : String) return Boolean is
         File : Character_IO.File_Type;
         Buffer : String (1 .. 65_536);
         Last : Natural := 0;
      begin
         Character_IO.Open (File, Character_IO.In_File, Path);
         for Index in Buffer'Range loop
            declare
               Item : Character;
            begin
               Character_IO.Read (File, Item);
               Buffer (Index) := Item;
               Last := Index;
            exception
               when Character_IO.End_Error =>
                  exit;
            end;
         end loop;
         Character_IO.Close (File);

         if Last = 0 then
            return False;
         end if;

         declare
            Contents : constant String := Buffer (1 .. Last);
         begin
            declare
               Port_Index : constant Natural := Index (Contents, Hex_Port);
            begin
               if Port_Index /= 0
                 and then Index (Contents (Port_Index .. Contents'Last), "0A")
                   /= 0
               then
                  return True;
               end if;
            end;
         end;

         return False;
      exception
         when others =>
            if Character_IO.Is_Open (File) then
               Character_IO.Close (File);
            end if;
            return False;
      end In_File;
   begin
      return In_File ("/proc/net/tcp") or else In_File ("/proc/net/tcp6");
   end Listening_Port;

   function File_Contains (Path : String; Needle : String) return Boolean is
      File : Ada.Text_IO.File_Type;
   begin
      if not Exists (Path) then
         return False;
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Line : constant String := Ada.Text_IO.Get_Line (File);
         begin
            if Ada.Strings.Fixed.Index (Line, Needle) /= 0 then
               Ada.Text_IO.Close (File);
               return True;
            end if;
         end;
      end loop;
      Ada.Text_IO.Close (File);
      return False;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return False;
   end File_Contains;

   function Bool (Value : Boolean) return String is
     (if Value then "true" else "false");

   Disk_Present : constant Boolean :=
     Exists (VM_Dir & "/a11y-win11.qcow2");
   ISO_Present : constant Boolean :=
     Exists (VM_Dir & "/Win11_Enterprise_Eval_25H2_en-us.iso");
   Setup_ISO_Present : constant Boolean :=
     Exists (VM_Dir & "/guest_setup.iso");
   SSH_Key_Present : constant Boolean :=
     Exists (VM_Dir & "/guest_setup/a11y_vm_ed25519");
   Exchange_Image_Present : constant Boolean :=
     Exists (VM_Dir & "/exchange_mbr.img");
   Exchange_Probe_Script_Present : constant Boolean :=
     Exists (VM_Dir & "/exchange_probe.cmd");
   Exchange_Probe_Result_Present : constant Boolean :=
     Exists (VM_Dir & "/a11y-win-probe.txt");
   Exchange_Probe_Done : constant Boolean :=
     File_Contains (VM_Dir & "/a11y-win-probe.txt", "a11y Windows VM probe")
     and then File_Contains
       (VM_Dir & "/a11y-win-probe.txt", "drive=F:");
   Exchange_UIA_Client_Available : constant Boolean :=
     File_Contains
       (VM_Dir & "/a11y-win-probe.txt", "uia_client_available=true");
   Public_UIA_Provider_Result_Present : constant Boolean :=
     Exists (VM_Dir & "/a11y-uia-public-provider.txt");
   Public_UIA_Client_Found_Provider : constant Boolean :=
     File_Contains
       (VM_Dir & "/a11y-uia-public-provider.txt",
        "public_uia_client_found_provider=true");
   Public_UIA_Provider_Invoke_Succeeded : constant Boolean :=
     File_Contains
       (VM_Dir & "/a11y-uia-public-provider.txt",
        "invoke_count=1")
     and then File_Contains
       (VM_Dir & "/a11y-uia-public-provider.txt", "status=success");
   Native_UIA_Client_Result_Present : constant Boolean :=
     Exists (VM_Dir & "/a11y-windows-native-client.txt");
   Native_UIA_Client_Built : constant Boolean :=
     File_Contains
       (VM_Dir & "/a11y-windows-native-client.txt",
        "default_exit=0")
     and then File_Contains
       (VM_Dir & "/a11y-windows-native-client.txt",
        "probe_external_client_exit=0")
     and then File_Contains
       (VM_Dir & "/a11y-windows-native-client.txt",
        "uia_router_tests_exit=0");
   Native_UIA_Client_Traversal_Succeeded : constant Boolean :=
     Native_UIA_Client_Built
     and then File_Contains
       (VM_Dir & "/a11y-windows-native-client.txt",
        """transport_status"": ""native_client_available""")
     and then File_Contains
       (VM_Dir & "/a11y-windows-native-client.txt",
        """external_client_traversal_observed"": true")
     and then File_Contains
       (VM_Dir & "/a11y-windows-native-client.txt",
        """native_conformance_ready"": true")
     and then File_Contains
       (VM_Dir & "/a11y-windows-native-client.txt",
        """status"": ""success""");
   Monitor_Socket_Present : constant Boolean :=
     Exists (VM_Dir & "/monitor.sock");
   VNC_Listening : constant Boolean := Listening_Port ("1717");
   RDP_Forward_Listening : constant Boolean := Listening_Port ("D08D");
   WinRM_Forward_Listening : constant Boolean := Listening_Port ("DAB1");
   SSH_Forward_Listening : constant Boolean := Listening_Port ("D7B6");
   VNC_Connectable : constant Boolean := TCP_Connectable (5911);
   RDP_Connectable : constant Boolean := TCP_Connectable (53389);
   WinRM_Connectable : constant Boolean := TCP_Connectable (55985);
   SSH_Connectable : constant Boolean := TCP_Connectable (55222);
   SSH_Banner_Ready : constant Boolean := SSH_Banner_Responsive (55222);
   VM_Prepared : constant Boolean :=
     Disk_Present and then ISO_Present and then Setup_ISO_Present
     and then SSH_Key_Present;
   VM_Running : constant Boolean := Monitor_Socket_Present;
   Guest_Remote_Channel_Ready : constant Boolean :=
     SSH_Banner_Ready;
   Guest_Execution_Channel_Ready : constant Boolean :=
     Guest_Remote_Channel_Ready or else Exchange_Probe_Done;
   Can_Attempt_Public_UIA : constant Boolean :=
     VM_Prepared
     and then VM_Running
     and then
       (Guest_Remote_Channel_Ready or else Exchange_UIA_Client_Available);

begin
   if Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--json"
   then
      Ada.Text_IO.Put_Line ("{");
      Ada.Text_IO.Put_Line
        ("  ""schema"": ""org.a11y.windows_uia_vm_probe.v1"",");
      Ada.Text_IO.Put_Line ("  ""platform"": ""Windows"",");
      Ada.Text_IO.Put_Line ("  ""native_api"": ""UI Automation"",");
      Ada.Text_IO.Put_Line
        ("  ""vm_directory"": """ & VM_Dir & """,");
      Ada.Text_IO.Put_Line
        ("  ""disk_present"": " & Bool (Disk_Present) & ",");
      Ada.Text_IO.Put_Line
        ("  ""evaluation_iso_present"": " & Bool (ISO_Present) & ",");
      Ada.Text_IO.Put_Line
        ("  ""guest_setup_iso_present"": "
         & Bool (Setup_ISO_Present) & ",");
      Ada.Text_IO.Put_Line
        ("  ""guest_setup_ssh_key_present"": "
         & Bool (SSH_Key_Present) & ",");
      Ada.Text_IO.Put_Line
        ("  ""exchange_image_present"": "
         & Bool (Exchange_Image_Present) & ",");
      Ada.Text_IO.Put_Line
        ("  ""exchange_probe_script_present"": "
         & Bool (Exchange_Probe_Script_Present) & ",");
      Ada.Text_IO.Put_Line
        ("  ""exchange_probe_result_present"": "
         & Bool (Exchange_Probe_Result_Present) & ",");
      Ada.Text_IO.Put_Line
        ("  ""exchange_probe_done"": "
         & Bool (Exchange_Probe_Done) & ",");
      Ada.Text_IO.Put_Line
        ("  ""exchange_uia_client_available"": "
         & Bool (Exchange_UIA_Client_Available) & ",");
      Ada.Text_IO.Put_Line
        ("  ""public_uia_provider_result_present"": "
         & Bool (Public_UIA_Provider_Result_Present) & ",");
      Ada.Text_IO.Put_Line
        ("  ""public_uia_client_found_provider"": "
         & Bool (Public_UIA_Client_Found_Provider) & ",");
      Ada.Text_IO.Put_Line
        ("  ""public_uia_provider_invoke_succeeded"": "
         & Bool (Public_UIA_Provider_Invoke_Succeeded) & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_uia_client_result_present"": "
         & Bool (Native_UIA_Client_Result_Present) & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_uia_client_built"": "
         & Bool (Native_UIA_Client_Built) & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_uia_client_traversal_succeeded"": "
         & Bool (Native_UIA_Client_Traversal_Succeeded) & ",");
      Ada.Text_IO.Put_Line
        ("  ""monitor_socket_present"": "
         & Bool (Monitor_Socket_Present) & ",");
      Ada.Text_IO.Put_Line
        ("  ""vnc_listening"": " & Bool (VNC_Listening) & ",");
      Ada.Text_IO.Put_Line
        ("  ""rdp_forward_listening"": "
         & Bool (RDP_Forward_Listening) & ",");
      Ada.Text_IO.Put_Line
        ("  ""winrm_forward_listening"": "
         & Bool (WinRM_Forward_Listening) & ",");
      Ada.Text_IO.Put_Line
        ("  ""ssh_forward_listening"": "
         & Bool (SSH_Forward_Listening) & ",");
      Ada.Text_IO.Put_Line
        ("  ""vnc_connectable"": " & Bool (VNC_Connectable) & ",");
      Ada.Text_IO.Put_Line
        ("  ""rdp_connectable"": " & Bool (RDP_Connectable) & ",");
      Ada.Text_IO.Put_Line
        ("  ""winrm_connectable"": " & Bool (WinRM_Connectable) & ",");
      Ada.Text_IO.Put_Line
        ("  ""ssh_connectable"": " & Bool (SSH_Connectable) & ",");
      Ada.Text_IO.Put_Line
        ("  ""ssh_banner_responsive"": "
         & Bool (SSH_Banner_Ready) & ",");
      Ada.Text_IO.Put_Line
        ("  ""vm_prepared"": " & Bool (VM_Prepared) & ",");
      Ada.Text_IO.Put_Line
        ("  ""vm_running"": " & Bool (VM_Running) & ",");
      Ada.Text_IO.Put_Line
        ("  ""guest_remote_channel_ready"": "
         & Bool (Guest_Remote_Channel_Ready) & ",");
      Ada.Text_IO.Put_Line
        ("  ""guest_execution_channel_ready"": "
         & Bool (Guest_Execution_Channel_Ready) & ",");
      Ada.Text_IO.Put_Line
        ("  ""can_attempt_public_uia_client"": "
         & Bool (Can_Attempt_Public_UIA) & ",");
      Ada.Text_IO.Put_Line
        ("  ""next_required_evidence"": "
         & (if Can_Attempt_Public_UIA then
              (if Native_UIA_Client_Traversal_Succeeded then
                 """windows_uia_automated_native_qualification_complete"""
               elsif Public_UIA_Provider_Invoke_Succeeded then
                 """run_native_client_uia_against_exported_a11y_fixture_provider"""
               else
                 """run_public_uia_provider_probe_in_windows_vm""")
            else
              """enable_guest_execution_channel_and_run_native_client_uia"""));
      Ada.Text_IO.Put_Line ("}");
   else
      Ada.Text_IO.Put_Line ("# Windows UIA VM Probe");
      Ada.Text_IO.Put_Line ("");
      Ada.Text_IO.Put_Line
        ("VM prepared: " & Bool (VM_Prepared));
      Ada.Text_IO.Put_Line
        ("VM running: " & Bool (VM_Running));
      Ada.Text_IO.Put_Line
        ("VNC connectable: " & Bool (VNC_Connectable));
      Ada.Text_IO.Put_Line
        ("RDP connectable: " & Bool (RDP_Connectable));
      Ada.Text_IO.Put_Line
        ("WinRM connectable: " & Bool (WinRM_Connectable));
      Ada.Text_IO.Put_Line
        ("SSH connectable: " & Bool (SSH_Connectable));
      Ada.Text_IO.Put_Line
        ("SSH banner responsive: " & Bool (SSH_Banner_Ready));
      Ada.Text_IO.Put_Line
        ("Exchange probe result present: "
         & Bool (Exchange_Probe_Result_Present));
      Ada.Text_IO.Put_Line
        ("Exchange probe done: " & Bool (Exchange_Probe_Done));
      Ada.Text_IO.Put_Line
        ("Exchange UIA client available: "
         & Bool (Exchange_UIA_Client_Available));
      Ada.Text_IO.Put_Line
        ("Public UIA provider result present: "
         & Bool (Public_UIA_Provider_Result_Present));
      Ada.Text_IO.Put_Line
        ("Public UIA client found provider: "
         & Bool (Public_UIA_Client_Found_Provider));
      Ada.Text_IO.Put_Line
        ("Public UIA provider invoke succeeded: "
         & Bool (Public_UIA_Provider_Invoke_Succeeded));
      Ada.Text_IO.Put_Line
        ("Native UIA client result present: "
         & Bool (Native_UIA_Client_Result_Present));
      Ada.Text_IO.Put_Line
        ("Native UIA client built: "
         & Bool (Native_UIA_Client_Built));
      Ada.Text_IO.Put_Line
        ("Native UIA client traversal succeeded: "
         & Bool (Native_UIA_Client_Traversal_Succeeded));
      Ada.Text_IO.Put_Line
        ("Guest remote channel ready: "
         & Bool (Guest_Remote_Channel_Ready));
      Ada.Text_IO.Put_Line
        ("Guest execution channel ready: "
         & Bool (Guest_Execution_Channel_Ready));
      Ada.Text_IO.Put_Line
        ("Can attempt public UIA client: "
         & Bool (Can_Attempt_Public_UIA));
   end if;
end Windows_VM_Probe;
