with Ada.Command_Line;
with Ada.Text_IO;

with A11y_Release_Qualification;
with Project_Tools.Files;

procedure Release_Qualification is
begin
   if Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--json"
   then
      Ada.Text_IO.Put (A11y_Release_Qualification.JSON);
   elsif Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--platform-evidence-summary"
   then
      Ada.Text_IO.Put
        (A11y_Release_Qualification.Platform_Evidence_Summary_JSON);
   elsif Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--project-completion-gate"
   then
      Ada.Text_IO.Put
        (A11y_Release_Qualification.Project_Completion_Gate_JSON);
   elsif Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--require-project-completion"
   then
      Ada.Text_IO.Put
        (A11y_Release_Qualification.Project_Completion_Gate_JSON);
      if A11y_Release_Qualification.Project_Completion_Complete then
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
      else
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      end if;
   elsif Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--native-client-artifact-status"
   then
      Ada.Text_IO.Put
        (A11y_Release_Qualification.Native_Client_Artifact_Status_JSON);
   elsif Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--require-native-client-artifacts"
   then
      Ada.Text_IO.Put
        (A11y_Release_Qualification.Native_Client_Artifact_Status_JSON);
      if A11y_Release_Qualification.Native_Client_Artifacts_Complete then
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
      else
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      end if;
   elsif Ada.Command_Line.Argument_Count = 4
     and then Ada.Command_Line.Argument (1) =
       "--project-completion-gate-from-artifacts"
   then
      Ada.Text_IO.Put
        (A11y_Release_Qualification.Project_Completion_Gate_JSON
           (Project_Tools.Files.Read_Raw_File
              (Ada.Command_Line.Argument (2)),
            Project_Tools.Files.Read_Raw_File
              (Ada.Command_Line.Argument (3)),
            Project_Tools.Files.Read_Raw_File
              (Ada.Command_Line.Argument (4))));
   elsif Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--linux-atspi-evidence-template"
   then
      Ada.Text_IO.Put
        (A11y_Release_Qualification.Linux_ATSPI_Evidence_Template_JSON);
   elsif Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--linux-atspi-host-evidence"
   then
      Ada.Text_IO.Put
        (A11y_Release_Qualification.Linux_ATSPI_Host_Evidence_JSON);
   elsif Ada.Command_Line.Argument_Count = 2
     and then Ada.Command_Line.Argument (1) =
       "--linux-atspi-captured-evidence"
   then
      Ada.Text_IO.Put
        (A11y_Release_Qualification.Linux_ATSPI_Captured_Evidence_Status_JSON
           (Project_Tools.Files.Read_Raw_File
              (Ada.Command_Line.Argument (2))));
   elsif Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--windows-uia-evidence-template"
   then
      Ada.Text_IO.Put
        (A11y_Release_Qualification.Windows_UIA_Evidence_Template_JSON);
   elsif Ada.Command_Line.Argument_Count = 2
     and then Ada.Command_Line.Argument (1) =
       "--windows-uia-captured-evidence"
   then
      Ada.Text_IO.Put
        (A11y_Release_Qualification.Windows_UIA_Captured_Evidence_Status_JSON
           (Project_Tools.Files.Read_Raw_File
              (Ada.Command_Line.Argument (2))));
   elsif Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) =
       "--macos-nsaccessibility-evidence-template"
   then
      Ada.Text_IO.Put
        (A11y_Release_Qualification
           .MacOS_NSAccessibility_Evidence_Template_JSON);
   elsif Ada.Command_Line.Argument_Count = 2
     and then Ada.Command_Line.Argument (1) =
       "--macos-nsaccessibility-captured-evidence"
   then
      Ada.Text_IO.Put
        (A11y_Release_Qualification
           .MacOS_NSAccessibility_Captured_Evidence_Status_JSON
             (Project_Tools.Files.Read_Raw_File
                (Ada.Command_Line.Argument (2))));
   elsif Ada.Command_Line.Argument_Count = 2
     and then Ada.Command_Line.Argument (1) =
       "--macos-nsaccessibility-native-client-artifact"
   then
      Ada.Text_IO.Put
        (A11y_Release_Qualification
           .MacOS_NSAccessibility_Native_Client_Artifact_Status_JSON
             (Project_Tools.Files.Read_Raw_File
                (Ada.Command_Line.Argument (2))));
   elsif Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) =
       "--macos-nsaccessibility-native-client-artifact-status"
   then
      Ada.Text_IO.Put
        (A11y_Release_Qualification
           .MacOS_NSAccessibility_Native_Client_Artifact_File_Status_JSON);
   elsif Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) =
       "--require-macos-nsaccessibility-native-client-artifact"
   then
      Ada.Text_IO.Put
        (A11y_Release_Qualification
           .MacOS_NSAccessibility_Native_Client_Artifact_File_Status_JSON);
      if A11y_Release_Qualification
           .MacOS_NSAccessibility_Public_Client_Traversal_Observed
      then
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
      else
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      end if;
   elsif Ada.Command_Line.Argument_Count = 4
     and then Ada.Command_Line.Argument (1) =
       "--captured-evidence-summary"
   then
      Ada.Text_IO.Put
        (A11y_Release_Qualification.Captured_Evidence_Summary_JSON
           (Project_Tools.Files.Read_Raw_File
              (Ada.Command_Line.Argument (2)),
            Project_Tools.Files.Read_Raw_File
              (Ada.Command_Line.Argument (3)),
            Project_Tools.Files.Read_Raw_File
              (Ada.Command_Line.Argument (4))));
   else
      Ada.Text_IO.Put (A11y_Release_Qualification.Markdown);
   end if;
end Release_Qualification;
